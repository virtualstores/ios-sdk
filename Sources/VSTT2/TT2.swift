//
// VSTT2Manager
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import VSFoundation
import VSPositionKitTargets
import CoreGraphics
import UIKit

let version = "1.1.3"

final public class TT2: ITT2 {
    public var initialized: Bool { _tt2Internal != nil }
    public var stores: [TT2Store] { tt2Internal.internalStores.map({ $0.toTT2Store() }) }
    public var activeStores: [TT2Store] { tt2Internal.internalStoresActive.map({ $0.toTT2Store() }) }
    public var navigation: Navigation { tt2Internal.navigation }
    public var analytics: TT2AnalyticsManager { tt2Internal.analytics }
    public var floor: VSTT2FloorManager { tt2Internal.floorManager }
    public var position: Position { tt2Internal.position }
    public var events: TT2EventManager { analytics.eventManager }
    public var user: UserController { tt2Internal.user }
    public var recording: IRecordingManager { tt2Internal.recording }

    public var activeStore: TT2Store? { tt2Internal.activeStore.toTT2Store() }
    public var activeFloor: RtlsOptions? { floor.activeFloor }
    
    public private(set) var coordinateConverter: ICoordinateConverter?
    public private(set) var mapData: MapData?
    public private(set) var map: Map?
    public private(set) var mapZonesTree: Tree?

    // Only for testing purpose of floorchange. Will be removed once green lighted
    public var floorChangePublisher: CurrentValueSubject<String?, Never> = .init(nil)
    
    // MARK: Private members
    private let context: Context
    private let config = EnvironmentConfig()
    private var _tt2Internal: TT2Internal?
    private var tt2Internal: TT2Internal {
        guard let tt2Internal = _tt2Internal else { fatalError("tt2Internal is not initialized") }
        return tt2Internal
    }

    private var floorHeightDiff: Double?
    private var activeClient: Client? { tt2Internal.activeClient }

    private var cancellable = Set<AnyCancellable>()
    private var wifiCancellable = Set<AnyCancellable>()
    private var positionKitParams: ParameterPackage = .retail
    
    public init(with apiUrl: String, apiKey: String) {
        config.initCentralServerConnection(with: apiUrl, endPoint: .v1, apiKey: apiKey)
        context = Context(VSTT2Config(environment: config))
    }

    deinit {
        Injector.reset()
        _tt2Internal = nil
        cancellable.removeAll()
        wifiCancellable.removeAll()
    }

    // MARK: Initialize
    public func initialize(clientId: Int64, positionKitParams: ParameterPackage = .retail, completion: @escaping (Error?) -> ()) {
        self._tt2Internal = TT2Internal(config: config)
        self.tt2Internal.getClients(completion: { (error) in
            if let error = error {
                completion(error)
                return
            }

            guard
              let client = self.tt2Internal.internalClients.first(where: { $0.clientId == clientId }),
              let serverAddress = client.dataServerUrl,
              let apiKey = client.dataServerApiKey
            else {
              completion(VSTT2Error.missingData)
              return
            }

            self.tt2Internal.activeClient = client
            let config = EnvironmentConfig()
            config.initCentralServerConnection(with: serverAddress, endPoint: .v2, apiKey: apiKey)
            self.user.setup(clientId: clientId, config: config)
            self.positionKitParams = positionKitParams
            self.tt2Internal.getStores(with: clientId, completion: completion)
        })
    }
    
    public func initiate(store: TT2Store, completion: @escaping (Error?) -> ()) {
        ///check
        guard let currentStore = tt2Internal.internalStores.first(where: { $0.id == store.id }) else { return }

        self.tt2Internal.setActiveStore(storeId: currentStore.id)
        self.floor.setupFloors(with: currentStore.rtlsOptions)

        tt2Internal.getSwapLocations(for: currentStore.id, completion: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let swapLocations):
              self.floorHeightDiff = self.getHighestHeightDiff(swapLocations: swapLocations)

              let group = DispatchGroup()
              group.enter()
              if let rtls = currentStore.rtlsOptions.first(where: { $0.isDefault }) {
                  self.setActiveFloor(rtls: rtls) { (error) in
                      completion(error)
                      self.mapData?.swapLocations = swapLocations
                      group.leave()
                  }
              } else {
                  guard let rtls = currentStore.rtlsOptions.first else { return }
                  self.setActiveFloor(rtls: rtls) { (error) in
                      completion(error)
                      self.mapData?.swapLocations = swapLocations
                      group.leave()
                  }
              }

              self.floor.setup(swapLocations: swapLocations)
              if let startPositions = self.activeFloor?.scanLocations?.filter({ $0.type == .start }) {
                self.navigation.setup(startCodes: startPositions)
              }
              self.bindPublishers()

              group.enter()
              self.tt2Internal.getShelfGroups(for: currentStore.id, activeFloor: self.activeFloor) { [weak self] shelfGroups in
                  guard let config = self?.config else { return }
                  self?.position.setup(with: shelfGroups, config: config, store: currentStore)
                  group.leave()
              }

              group.notify(queue: .main) {
                  self.setupMap()
                  if let client = self.tt2Internal.internalClients.first(where: { $0.clientId == currentStore.clientId }), let converter = self.coordinateConverter {
                      self.tt2Internal.analytics.accuracyUploader = AccuracyUploader(store: currentStore, connection: self.config.centralServerConnection, client: client, converter: converter)
                      self.tt2Internal.deviceOrientationUploader = DeviceOrientationUploader(store: currentStore, connection: self.config.centralServerConnection, client: client)
                  }
              }
            case .failure(let error): completion(error)
            }
        })

        setupAnalytics(for: currentStore)
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
        analytics.stopCollectingHeatMapData()
        analytics.stopVisit()
        navigation.stop()
    }

    public func setActiveFloor(rtls: RtlsOptions) {
        self.setActiveFloor(rtls: rtls) { (error) in
            if let error = error {
                Logger(verbosity: .critical).log(message: "Floor change failed: \(error.localizedDescription)")
            } else {
                self.setupMap(changedFloor: true)
                if let shelfGroups = self.tt2Internal.shelfGroups[rtls.id] {
                    self.position.shelfGroups = shelfGroups
                }
            }
        }
    }
}

private extension TT2 {
    // MARK: Publishers
    private func bindPublishers() {
        floor.switchFloorPublisher
          .compactMap { $0 }
          .sink(receiveValue: { (data) in
              self.navigation.changeFloorStop()
              self.setActiveFloor(rtls: data.rtlsOptions) { (error) in
                  if let error = error {
                      Logger(verbosity: .critical).log(message: "Floor change failed: \(error.localizedDescription)")
                  } else {
                      self.setupMap(changedFloor: true)
                      if let shelfGroups = self.tt2Internal.shelfGroups[data.rtlsOptions.id] {
                          self.position.shelfGroups = shelfGroups
                      }
                      do {
                          try self.navigation.changeFloorStart(startPosition: data.point)
                          self.floorChangePublisher.send(data.rtlsOptions.name)
                      } catch {
                          Logger(verbosity: .critical).log(message: "Starting on new floor failed")
                      }
                  }
              }
          }).store(in: &cancellable)
    }

    private func bindWiFiPublishers() {
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
            let zones = self?.mapZonesTree?.getZonesForCurrentFloorLevel(),
            let zone = zones.first(where: { $0.navigationPoints[info.bssid] != nil }),
            let point = zone.navigationPoints.first(where: { $0.key == info.bssid })?.value.point
          else { return }

          self?.navigation.currentAccessPointPosition = point
        }).store(in: &wifiCancellable)
    }

    private func setupMap(changedFloor: Bool = false) {
      guard
        let rtls = activeFloor,
        let mapData = mapData,
        let converter = coordinateConverter,
        let navData = floor.navgraph[rtls.id],
        let start = floor.startCode,
        let stop = floor.stopCode,
        let zones = mapZonesTree?.getZonesFor(floorLevelId: rtls.id)
      else { return }

      let height = converter.convertFromMetersToPixels(input: rtls.heightInMeters)
      let navGraph = GraphDeserializer.deserialize(fromJsonData: navData, pixelHeight: height)

      let convertedAndFlippedStart = start.point.fromMeterToPixel(converter: converter).flipY(converter: converter)
      let convertedAndFlippedStop = stop.point.fromMeterToPixel(converter: converter).flipY(converter: converter)

      let pathfinder = VPSPathfinderAdapter(
        converter: converter,
        height: rtls.heightInMeters,
        width: rtls.widthInMeters,
        pixelsPerMeter: Float(rtls.pixelsPerMeter),
        navGraph: navGraph,
        startPosition: convertedAndFlippedStart,
        stopPosition: convertedAndFlippedStop
      )
      tt2Internal.mapController?.loadMap(with: mapData)
      let sharedProperties = floor.zoneData[rtls.id]?.sharedProperties
      tt2Internal.mapController?.setup(pathfinder: pathfinder, zones: zones, sharedProperties: sharedProperties, shelves: position.shelfGroups ?? [], changedFloor: changedFloor)
    }

    private func getHighestHeightDiff(swapLocations: [SwapLocation]) -> Double {
        var diff: Double = 0.0
        swapLocations.forEach { (swapLocation) in
            swapLocation.paths.forEach { (path) in
                diff = path.heightDiffInMeters > diff ? path.heightDiffInMeters : diff
            }
        }
        return diff
    }

    private func getLowestHeightDiff(swapLocations: [SwapLocation]) -> Double {
        var diff: Double = .greatestFiniteMagnitude
        swapLocations.forEach { (swapLocation) in
            swapLocation.paths.forEach { (path) in
                diff = path.heightDiffInMeters < diff ? path.heightDiffInMeters : diff
            }
        }
        return diff
    }

    private func setActiveFloor(rtls: RtlsOptions, completion: @escaping (Error?) -> ()) {
        guard let floorHeightDiff = floorHeightDiff else { return }
        self.floor.setActiveFloor(with: rtls) { [weak self] (mapFence, zoneData) in
            if let mapFence = mapFence {
                self?.setupMapfence(with: mapFence, floorHeightDiff: floorHeightDiff)
                self?.mapData = self?.tt2Internal.createMapData(rtlsOptions: rtls, mapFence: mapFence, coordinateConverter: self?.coordinateConverter)
            }

            self?.setupAnalytics(with: zoneData)
            completion(nil)
        }
    }

    private func setupMapfence(with data: MapFence, floorHeightDiff: Double) {
        guard let rtlsOption = activeFloor, let name = activeStore?.name else { return }
        
        let converter = BaseCoordinateConverter(heightInPixels: data.properties.height, widthInPixels: data.properties.width, pixelPerMeter: rtlsOption.pixelsPerMeter, pixelPerLatitude: 1000.0)
        coordinateConverter = converter

        let properties = ZoneProperties(description: nil, id: name, name: name, names: [], parentId: nil, fillColor: nil, fillColorSelected: nil, lineColor: nil, lineColorSelected: nil)
        mapZonesTree = Tree(root: Zone(id: UUID().uuidString, properties: properties, floorLevelId: rtlsOption.id, converter: converter), converter: converter, currentFloorLevelId: rtlsOption.id)

        navigation.positionKitManager.setupMapFence(
            with: data,
            rtlsOption: rtlsOption,
            floorheight: floorHeightDiff,
            parameterPackage: positionKitParams,
            userController: user,
            maxRecordingTimePerPartInMillis: tt2Internal.activeStore.positionServiceSettings?.intValues?["maxRecordingTimePerPartInMillis"]?.asLong
        )
    }
    
    private func setupAnalytics(for store: Store) {
        guard let serverAddress = store.statServerConnection.serverAddress, let apiKey = store.statServerConnection.apiKey else { return }
        let analyticsConfig = EnvironmentConfig()
        analyticsConfig.initCentralServerConnection(with: serverAddress, endPoint: .v2, apiKey: apiKey)
        analytics.setup(with: store, rtlsOptionId: self.activeFloor?.id, config: analyticsConfig)
        if let client = activeClient {
            user.setup(clientId: client.clientId, positionServiceSettings: store.positionServiceSettings, config: analyticsConfig)
        }
        tt2Internal.awsS3UploadManager.setup(store.hasSensorRecordingActive)
    }
    
    private func setupAnalytics(with zoneData: [Int64: ZoneData]?) {
        guard let rtlsOption = activeFloor, let store = activeStore, let zoneData = zoneData else { return }

        zoneData.forEach { (key, value) in
            guard let rtls = floor.floors.first(where: { $0.id == key }) else { return }
            mapZonesTree?.add(rtls, value.mapZones, value.mapZonesPoints)
        }

        guard let mapZones = self.mapZonesTree?.getZonesFor(floorLevelId: rtlsOption.id) else { return }

        analytics.update(rtlsOptionId: rtlsOption.id)
        analytics.zoneManager.setup(with: mapZones, rtlsOptions: rtlsOption)
        analytics.eventManager.setup(with: store.id, zones: mapZones, rtlsOptionsId: rtlsOption.id, config: config)
    }
}
