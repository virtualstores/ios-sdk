//
// VSTT2Manager
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import VSFoundation
import VSPositionKit
import CoreLocation
import UIKit

final public class TT2: ITT2 {
    public var initialized: Bool { _tt2Internal != nil }
    public var stores: [TT2Store] { tt2Internal.internalStores.map({ $0.toTT2Store() }) }
    public var activeStores: [TT2Store] { tt2Internal.internalStoresActive.map({ $0.toTT2Store() }) }
    public var navigation: Navigation { tt2Internal.navigation }
    public var analytics: TT2AnalyticsManager { tt2Internal.analytics }
    public var floor: VSTT2Floor { tt2Internal.floorManager }
    public var position: Position { tt2Internal.position }
    public var events: TT2EventManager { tt2Internal.analytics.eventManager }
    public var user: IUserManager { tt2Internal.user }
    public var recording: IRecordingManager { tt2Internal.recording }

    public var activeStore: TT2Store { tt2Internal.activeStore.toTT2Store() }
    public var activeFloor: RtlsOptions { floor.activeFloor }
    
    public private(set) var zonesTree: TT2ZonesTree?

    var coordinateConverter: ICoordinateConverter? { tt2Internal.floorManager.getActiveConverter.invoke() }
    var mapData: MapData?
    var map: Map?

    // Only for testing purpose of floorchange. Will be removed once green lighted
    public var floorChangePublisher: CurrentValueSubject<String?, Never> = .init(nil)

    static let version = "2.4.1"

    // MARK: Private members
    private let context: Context
    private var _tt2Internal: TT2Internal?
    private var tt2Internal: TT2Internal {
        guard let tt2Internal = _tt2Internal else { fatalError("tt2Internal is not initialized") }
        return tt2Internal
    }

    private var floorHeightDiff: Double?
    private var activeClient: Client { tt2Internal.activeClient }

    private var cancellable = Set<AnyCancellable>()
    private var wifiCancellable = Set<AnyCancellable>()
    private var positionKitParams: ParameterPackage = .retail
    
    public init(with apiUrl: String, apiKey: String, params: TT2ModelParams? = nil) {
        context = Context(VSTT2Config(environment: EnvironmentConfig()))
        _tt2Internal = TT2Internal()
        tt2Internal.config.initCentralServerConnection(with: apiUrl, endPoint: .v1, apiKey: apiKey)
        tt2Internal.mlModelManager.setup(params: params)
        URLCache().removeAllCachedResponses()
    }

    deinit {
        _tt2Internal = nil
        cancellable.removeAll()
        wifiCancellable.removeAll()
    }

    // MARK: Initialize
    public func initialize(clientId: Int64, positionKitParams: ParameterPackage = .retail, completion: @escaping (Error?) -> ()) {
        tt2Internal.getClients(completion: { [self] (result) in
            switch result {
            case .success(let clients):
                guard
                  let client = clients.first(where: { $0.clientId == clientId }),
                  let serverAddress = client.dataServerUrl,
                  let apiKey = client.dataServerApiKey
                else { completion(VSTT2Error.missingData); return }

                tt2Internal.setActiveClient.invoke(clientId: clientId)
                tt2Internal.config.initAnalyticsServerConnection(with: serverAddress, endPoint: .v2, apiKey: apiKey)
                self.positionKitParams = positionKitParams
                tt2Internal.getStores(with: clientId, completion: completion)
            case .failure(let error):
                completion(error)
            }
        })
    }
    
    public func initiate(store: TT2Store, completion: @escaping (Error?) -> ()) {
        ///check
        guard let currentStore = tt2Internal.internalStores.first(where: { $0.id == store.id }) else { return }

        tt2Internal.setActiveStore(storeId: currentStore.id)
        tt2Internal.floorManager.setupFloors(with: currentStore.rtlsOptions)

        tt2Internal.getSwapLocations() { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let swapLocations):
              floorHeightDiff = getHighestHeightDiff(swapLocations: swapLocations)

              let group = DispatchGroup()
              group.enter()
              if let rtls = currentStore.rtlsOptions.first(where: { $0.isDefault }) {
                  setActiveFloor(rtls: rtls) {
                      self.mapData?.swapLocations = swapLocations
                      group.leave()
                  }
              } else {
                  guard let rtls = currentStore.rtlsOptions.first else { return }
                  setActiveFloor(rtls: rtls) {
                      self.mapData?.swapLocations = swapLocations
                      group.leave()
                  }
              }

              tt2Internal.floorManager.setup(swapLocations: swapLocations)
              bindPublishers()

              group.notify(queue: .main) {
                  if let shelfGroups = self.tt2Internal.floorManager.getActiveShelfGroups.invoke() {
                      self.tt2Internal.position.setup(with: shelfGroups, store: currentStore)
                  }
                  if let startPositions = self.activeFloor.scanLocations?.filter({ $0.type == .start }), let zones = self.zonesTree?.getZonesForCurrentFloorLevel() {
                      self.tt2Internal.navigation.setup(
                        startCodes: startPositions,
                        inAndOutZone: InAndOutZone(triggers: zones.map({ InAndOutZone.Trigger(id: $0.name, polygon: $0.points) }))
                      )
                  }
                  self.setupMap()
                  completion(nil)
                  self.setupAnalytics(for: currentStore)
              }
            case .failure(let error): completion(error)
            }
        }
    }

    public func initiate(storeId: Int64, completion: @escaping (Error?) -> Void) {
        guard let store = stores.first(where: { $0.id == storeId }) else { completion(VSTT2Error.missingData); return }
        initiate(store: store, completion: completion)
    }

    // MARK: Setters
    public func set(map: IMapController) {
        tt2Internal.mapController = map
        setupMap()
    }

    public func set(wifi: IWiFiController) {
        tt2Internal.wifiController = wifi
        bindWiFiPublishers()
    }

    public func set(automaticActivationOfUserMark: Bool) {
        tt2Internal.automaticActivationOfUserMark = automaticActivationOfUserMark
    }
    
    public func getMapData() -> MapData? {
        mapData
    }

    public func stop() {
        navigation.stop()
        analytics.stopCollectingHeatMapData()
        analytics.stopVisit()
    }

    public func setActiveFloor(rtls: RtlsOptions) {
        setActiveFloor(rtls: rtls) {
            self.setupMap(changedFloor: true)
        }
    }

    public func initRealWorldConverter() {
      tt2Internal.initRealWorldConverter()
    }

    public func initRealWorldConverter(point: CGPoint) {
      tt2Internal.initRealWorldConverter(point: point)
    }

    public func processMLPath(coordinate: CLLocationCoordinate2D, clearAnalytics: Bool) -> MLProcessedPath? {
      tt2Internal.processMLPath(coordinate: coordinate, clearAnalytics: clearAnalytics)
    }

    public func addProcessedMLPathToAnalytics(coordinate: CLLocationCoordinate2D) {
      tt2Internal.addProcessedMLPathToAnalytics(coordinate: coordinate)
    }

    public func syncAngleCorrection(angle: Double, coordinate: CLLocationCoordinate2D) {
      tt2Internal.syncAngleCorrection(angle: angle, coordinate: coordinate)
    }
}

private extension TT2 {
    // MARK: Publishers
    func bindPublishers() {
        tt2Internal.floorManager.switchFloorPublisher
          .compactMap { $0 }
          .sink(receiveValue: { (data) in
              self.tt2Internal.navigation.changeFloorStop()
              self.setActiveFloor(rtls: data.rtlsOptions) {
                  self.setupMap(changedFloor: true)
                  do {
                      try self.tt2Internal.navigation.changeFloorStart(startPosition: data.point)
                      self.floorChangePublisher.send(data.rtlsOptions.name)
                  } catch {
                      Logger(verbosity: .critical).log(message: "Starting on new floor failed")
                  }
              }
          }).store(in: &cancellable)
    }

    func bindWiFiPublishers() {
      wifiCancellable.removeAll()
      tt2Internal.wifiController?.wifiInfoPublisher
        .compactMap { $0 }
        .sink(receiveCompletion: { (result) in
          switch result {
          case .finished: break
          case .failure(let error): Logger(verbosity: .info).log(message: "WiFi Error: \(error)")
          }
        }, receiveValue: { [weak self] (info) in
          guard
            let zones = self?.zonesTree?.getZonesForCurrentFloorLevel(),
            let zone = zones.first(where: { $0.navigationPoints[info.bssid] != nil }),
            let point = zone.navigationPoints.first(where: { $0.key == info.bssid })?.value.point
          else { return }

          self?.tt2Internal.navigation.currentAccessPointPosition = point
        }).store(in: &wifiCancellable)
    }

    func setupMap(changedFloor: Bool = false) {
      guard
        let mapData = mapData,
        let converter = coordinateConverter,
        let navData = tt2Internal.floorManager.getActiveNavGraph.invoke(),
        let start = tt2Internal.floorManager.startCode,
        let stop = tt2Internal.floorManager.stopCode,
        let zones = zonesTree?.getZonesFor(floorLevelId: activeFloor.id)
      else { return }

      let height = converter.convertFromMetersToPixels(input: activeFloor.heightInMeters)
      let navGraph = GraphDeserializer.deserialize(fromJsonData: navData, pixelHeight: height)

      let convertedAndFlippedStart = start.point.fromMeterToPixel(converter: converter).flipY(converter: converter)
      let convertedAndFlippedStop = stop.point.fromMeterToPixel(converter: converter).flipY(converter: converter)

      let pathfinder = VPSPathfinderAdapter(
        converter: converter,
        height: activeFloor.heightInMeters,
        width: activeFloor.widthInMeters,
        pixelsPerMeter: Float(activeFloor.pixelsPerMeter),
        navGraph: navGraph,
        startPosition: convertedAndFlippedStart,
        stopPosition: convertedAndFlippedStop
      )
      tt2Internal.mapController?.loadMap(with: mapData)
      let sharedProperties = tt2Internal.floorManager.getActiveMapZones.invoke()?.sharedProperties
      tt2Internal.mapController?.setup(pathfinder: pathfinder, zones: zones, sharedProperties: sharedProperties, shelves: position.shelfGroups ?? [], changedFloor: changedFloor)
    }

    func getHighestHeightDiff(swapLocations: [SwapLocation]) -> Double {
      swapLocations.map { $0.paths.map { $0.heightDiffInMeters } }.flatMap { $0 }.max() ?? 0.0
    }

    func getLowestHeightDiff(swapLocations: [SwapLocation]) -> Double {
      swapLocations.map { $0.paths.map { $0.heightDiffInMeters } }.flatMap { $0 }.min() ?? 0.0
    }

    func setActiveFloor(rtls: RtlsOptions, completion: @escaping () -> ()) {
        guard let floorHeightDiff = floorHeightDiff else { return }
        tt2Internal.floorManager.setActiveFloor(with: rtls) { [weak self] (mapFence, zoneData) in
            if let mapFence = mapFence {
                self?.setupMapfence(with: mapFence, floorHeightDiff: floorHeightDiff)
                self?.mapData = self?.tt2Internal.createMapData(rtlsOptions: rtls, mapFence: mapFence, coordinateConverter: self?.coordinateConverter)
            }

            self?.setupAnalytics(with: zoneData)
            completion()
        }
    }

    func setupMapfence(with data: MapFence, floorHeightDiff: Double) {
        guard let converter = coordinateConverter as? BaseCoordinateConverter else { return }
        let name = activeStore.name
        let properties = ZoneProperties(id: name, name: name, names: [name])
        zonesTree = TT2ZonesTree(root: Zone(id: UUID().uuidString, floorLevelId: activeFloor.id, properties: properties, converter: converter), converter: converter, currentFloorLevelId: activeFloor.id)
        tt2Internal.navigation.positionManager.setupMapFence(
            with: data,
            rtlsOption: activeFloor,
            floorheight: floorHeightDiff,
            parameterPackage: positionKitParams,
            automaticSensorRecording: tt2Internal.automaticSensorRecording,
            positionServiceSettings: tt2Internal.activeStore.positionServiceSettings,
            converter: converter,
            modelManger: tt2Internal.mlModelManager
        )
    }
    
    func setupAnalytics(for store: Store) {
        guard let serverAddress = store.statServerConnection.serverAddress, let apiKey = store.statServerConnection.apiKey else { return }
        tt2Internal.config.initAnalyticsServerConnection(with: serverAddress, endPoint: .v2, apiKey: apiKey)
        tt2Internal.analytics.setup()
    }
    
    func setupAnalytics(with zoneData: [Int64: ZoneData]?) {
        guard let zoneData = zoneData else { return }

        zoneData.forEach { (key, value) in
            guard let rtls = floor.floors.first(where: { $0.id == key }) else { return }
            zonesTree?.add(rtls, value.mapZones, value.mapZonesPoints)
        }

        guard let mapZones = zonesTree?.getZonesFor(floorLevelId: activeFloor.id) else { return }

        tt2Internal.analytics.zoneManager.setup(with: mapZones, rtlsOptions: activeFloor)
        tt2Internal.analytics.eventManager.setup(with: activeStore.id, zones: mapZones, rtlsOptionsId: activeFloor.id)
    }
}
