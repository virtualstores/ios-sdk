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
    public var lease: ILeaseManager { tt2Internal.leaseManager }

    public var activeStore: TT2Store { tt2Internal.activeStore.toTT2Store() }
    public var activeFloor: RtlsOptions { floor.activeFloor }
    
    public var zonesTree: TT2ZonesTree { tt2Internal.getZonesTree.invoke() }

    var coordinateConverter: ICoordinateConverter? { tt2Internal.floorManager.getActiveConverter.invoke() }
    var mapData: MapData?
    var map: Map?

    // Only for testing purpose of floorchange. Will be removed once green lighted
    public var floorChangePublisher: CurrentValueSubject<String?, Never> = .init(nil)

    static let version = "2.7.0"

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
    private var settings: TT2Settings { tt2Internal.getTT2Settings.invoke() }

    public init(connectionSettings: EnvironmentConfig.Settings, authSettings: AuthSettings, settings: TT2Settings) {
      URLCache.shared.removeAllCachedResponses()
      context = Context(VSTT2Config(environment: EnvironmentConfig()))
      _tt2Internal = TT2Internal(connectionSettings: connectionSettings, authSettings: authSettings, settings: settings)
    }

    deinit {
        _tt2Internal = nil
        cancellable.removeAll()
        wifiCancellable.removeAll()
    }

    // MARK: Initialize
    public func initialize(clientId: Int64, positionKitParams: ParameterPackage = .retail, returnOn queue: DispatchQueue = .main, completion: @escaping (Error?) -> ()) {
      DispatchQueue.global(qos: .background).async { [weak self] in
        guard let self = self else { return }
        let group = DispatchGroup()
        group.enter()
        tt2Internal.login.invoke { (error) in
          group.leave()
        }
        group.wait()
        group.enter()
        tt2Internal.getClients() { [weak self] (result) in
          switch result {
          case .success(_):
            guard let self = self else { queue.async { completion(VSTT2Error.missingData) }; return }
            tt2Internal.setActiveClient.invoke(clientId: clientId)
            self.positionKitParams = positionKitParams
            tt2Internal.getStores(with: clientId) { (error) in
              if let error = error {
                queue.async { completion(error) }
              } else {
                group.leave()
              }
            }
          case .failure(let error):
            queue.async { completion(error) }
          }
        }

        group.enter()
        tt2Internal.mlModelManager.fetchInterface { (error) in
          if let error = error {
            queue.async { completion(error) }
          } else {
            group.leave()
          }
        }

        switch group.wait(timeout: .now() + 120) {
        case .success:
          queue.async { completion(nil) }
        case .timedOut:
          queue.async { completion(VSTT2Error.timeout) }
        }
      }
    }
    
    public func initiate(store: TT2Store, completion: @escaping (Error?) -> ()) {
        guard let currentStore = tt2Internal.internalStores.first(where: { $0.id == store.id }) else { return }

        tt2Internal.setActiveStore(storeId: currentStore.id)

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

              bindPublishers()

              group.notify(queue: .main) {
                  self.tt2Internal.position.setup()
                  if let zones = self.zonesTree.getZonesForCurrentFloorLevel() {
                      self.tt2Internal.navigation.setup(
                        inAndOutZone: InAndOutZone(triggers: zones.map({ InAndOutZone.Trigger(id: $0.id, polygon: $0.points) }))
                      )
                  }
                  self.setupMap()
                  self.setupAnalytics(for: currentStore)
                  completion(nil)
              }
            case .failure(let error):
              DispatchQueue.main.async { completion(error) }
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

    public func set(vpsEngine: TT2Settings.TT2Engine) {
        tt2Internal.set(tt2Settings: .init(engine: vpsEngine, params: settings.params))
    }

    public func getMapData() -> MapData? {
        mapData
    }

    public func stop() {
        tt2Internal.stopTT2.invoke()
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
            let zones = self?.zonesTree.getZonesForCurrentFloorLevel(),
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
        let zones = zonesTree.getZonesFor(floorLevelId: activeFloor.id)
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
            guard let self = self else { return }
            setupMapfence(with: mapFence, floorHeightDiff: floorHeightDiff)
            mapData = tt2Internal.createMapData(rtlsOptions: rtls, mapFence: mapFence, coordinateConverter: coordinateConverter)
            setupAnalytics(with: zoneData)
            completion()
        }
    }

    func setupMapfence(with data: MapFence, floorHeightDiff: Double) {
        guard let converter = coordinateConverter else { return }
        tt2Internal.navigation.vpsPosition.setupMapFence(
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
        if tt2Internal.config.connection.tt2DataServer == nil, let serverAddress = store.statServerConnection.serverAddress {
          tt2Internal.config.connection.tt2DataServer = .init(
            baseUrl: serverAddress.trimmingCharacters(in: .init(charactersIn: "/"))
              .appending("/")
              .appending(EnvironmentConfig.EndPoints.v2.rawValue),
            authType: .apiKey
          )
        }
        if let apiKey = store.statServerConnection.apiKey {
          tt2Internal.setApiKey.invoke(type: .analytics, value: apiKey)
        }
        tt2Internal.analytics.setup()
    }
    
    func setupAnalytics(with zoneData: [Int64: ZoneData]?) {
        guard let zoneData = zoneData else { return }

        zoneData.forEach { (key, value) in
            guard let rtls = floor.floors.first(where: { $0.id == key }) else { return }
            zonesTree.add(rtls, value.mapZones, value.mapZonesPoints)
        }

        guard let mapZones = zonesTree.getZonesFor(floorLevelId: activeFloor.id) else { return }
        tt2Internal.analytics.zoneManager.setup(with: mapZones, rtlsOptions: activeFloor)
        tt2Internal.analytics.eventManager.setup(with: activeStore.id, zones: mapZones, rtlsOptionsId: activeFloor.id)
    }
}

public struct TT2Settings {
  let engine: TT2Engine
  let params: TT2ModelParams
  let isAutomaticFloorChangeEanbled: Bool

  public init(engine: TT2Engine = .indoor, params: TT2ModelParams = .init(), isAutomaticFloorChangeEanbled: Bool = true) {
    self.engine = engine
    self.params = params
    self.isAutomaticFloorChangeEanbled = isAutomaticFloorChangeEanbled
  }

  public enum TT2Engine: String {
    case gpsFusion = "GPS_FUSION"
    case indoor = "INDOOR"
    case openTerrain = "OPEN_TERRAIN"
  }

  public struct TT2ModelParams {
    let target: Int
    let targetMLModelVersion: Int?
    let targetNLModelVersion: Int?

    public init(target: Int = 1, targetMLModelVersion: Int? = nil, targetNLModelVersion: Int? = nil) {
      self.target = target
      self.targetMLModelVersion = targetMLModelVersion
      self.targetNLModelVersion = targetNLModelVersion
    }
  }
}
