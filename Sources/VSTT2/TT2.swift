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
    public var stores: [TT2Store] { tt2Internal.internalStores.map({ $0.toTT2Store() }) }
    public var activeStores: [TT2Store] { tt2Internal.internalStoresActive.map({ $0.toTT2Store() }) }
    public var navigation: Navigation { tt2Internal.navigation }
    public var analytics: TT2Analytics { tt2Internal.analytics }
    public var floor: VSTT2Floor { tt2Internal.floorManager }
    public var position: Position { tt2Internal.position }
    public var events: TT2EventManager { tt2Internal.analytics.eventManager }
    public var user: IUserManager { tt2Internal.user }
    public var recording: IRecordingManager { tt2Internal.recording }
    public var lease: ILeaseManager { tt2Internal.leaseManager }

    public var activeStore: TT2Store { get throws { try tt2Internal.getActiveStore.invoke().toTT2Store() } }
    public var activeFloor: RtlsOptions { get throws { try floor.activeFloor } }

    public var zonesTree: TT2ZonesTree { get throws { try tt2Internal.getZonesTree.invoke() } }

    var coordinateConverter: ICoordinateConverter? { try? tt2Internal.floorManager.getActiveConverter.invoke() }
    var mapData: MapData?

    // Only for testing purpose of floorchange. Will be removed once green lighted
    public var floorChangePublisher: CurrentValueSubject<String?, Never> = .init(nil)

    static let version = "2.14.1"

    // MARK: Private members
    private let tag: String = "TT2"
    private var context: Context?
    private let tt2Internal: TT2Internal

    private var floorHeightDiff: Double?
    private var activeClient: Client? { tt2Internal.activeClient }

    private var cancellable = Set<AnyCancellable>()
    private var wifiCancellable = Set<AnyCancellable>()
    private var positionKitParams: ParameterPackage = .retail
    private var settings: TT2Settings { tt2Internal.getTT2Settings.invoke() }

    public init(connectionSettings: EnvironmentConfig.Settings, authSettings: AuthSettings, settings: TT2Settings) {
      URLCache.shared.removeAllCachedResponses()
      context = Context(VSTT2Config(environment: .init()))
      tt2Internal = TT2Internal(connectionSettings: connectionSettings, authSettings: authSettings, settings: settings)
      Logger.debugModeEnabled = settings.debugModeEnabled
      Logger.extendedDebugModeEnabled = settings.extendedDebugModeEnabled
    }

    @available(*, deprecated, message: "Please use init(connectionSettings:authSettings:settings:)")
    public convenience init(with apiUrl: String, apiKey: String, settings: TT2Settings = .init()) {
      self.init(
        connectionSettings: EnvironmentConfig.Direct(authType: .apiKey, tt2CentralServer: apiUrl),
        authSettings: .apiKey(apiKey),
        settings: settings
      )
    }

    deinit {
      Logger(verbosity: .info).log(tag: tag, message: "deinit")
      dispose()
    }
  
    /// Disposes both TT2 and TT2Map, remember to nil both.
    public func dispose() {
      Logger(verbosity: .info).log(tag: tag, message: "dispose")
      tt2Internal.dispose()
      mapData = nil
      context?.dispose()
      context = nil
      cancellable.removeAll()
      wifiCancellable.removeAll()
    }

    // MARK: Initialize
    public func initialize(clientId: Int64, positionKitParams: ParameterPackage = .retail, returnOn queue: DispatchQueue = .main, completion: @escaping (Error?) -> ()) {
      initialize(clientId: clientId, returnOn: queue)
        .timeout(120, scheduler: queue)
        .asFailure()
        .sink(receiveValue: completion)
        .store(in: &cancellable)
    }

    public func initialize(clientId: Int64, returnOn queue: DispatchQueue = .main) -> AnyPublisher<Void, Error> {
      tt2Internal.login.invoke()
        .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
          guard let self = self else { return .fail(with: TT2Error.missingData)}
          return Publishers.MergeMany(
            tt2Internal.fetchClient.invoke(),
            tt2Internal.mlModelManager.fetchInterface()
          )
          .collect()
          .tryMap { _ in
            try self.tt2Internal.setActiveClient.invoke(clientId: clientId)
          }
          .map { _ in () }
          .eraseToAnyPublisher()
        }
        .receive(on: queue)
        .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
          guard let self = self else { return .fail(with: TT2Error.missingData) }
          return tt2Internal.fetchStore.invoke(clientId: clientId)
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }

    public func initiate(store: TT2Store, completion: @escaping (Error?) -> ()) {
      initiate(store: store)
        .asFailure()
        .sink(receiveValue: completion)
        .store(in: &cancellable)
    }

    public func initiate(store: TT2Store) -> AnyPublisher<Void, Error> {
      guard let currentStore = tt2Internal.internalStores.first(where: { $0.id == store.id }) else { return .fail(with: TT2Error.missingData) }
      return .justOrFail{ try tt2Internal.setActiveStore(storeId: currentStore.id) }
        .flatMap { [weak self] _ -> AnyPublisher<[SwapLocation], Error> in
          guard let self = self else { return .fail(with: TT2Error.missingData) }
          return tt2Internal.getSwapLocations(storeId: currentStore.id)
        }
        .flatMap { [weak self] (swapLocations) -> AnyPublisher<Void, Error> in
          guard
            let self = self,
            let rtls = currentStore.rtlsOptions.first(where: { $0.isDefault }) ?? currentStore.rtlsOptions.first
          else { return .fail(with: TT2Error.missingData) }
          floorHeightDiff = getHighestHeightDiff(swapLocations: swapLocations)
          return setActiveFloor(rtls: rtls)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { _ in
              self.bindPublishers()
              self.mapData?.swapLocations = swapLocations
              self.tt2Internal.position.setup()
              if let zones = try? self.zonesTree.getZonesForCurrentFloorLevel() {
                self.tt2Internal.navigation.setup(
                  inAndOutZone: InAndOutZone(triggers: zones.map({ InAndOutZone.Trigger(id: $0.id, polygon: $0.points) }))
                )
              }
              self.setupMap()
              self.setupAnalytics(for: currentStore)
            })
            .eraseToAnyPublisher()
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }

    public func initiate(storeId: Int64, completion: @escaping (Error?) -> Void) {
        guard let store = stores.first(where: { $0.id == storeId }) else { completion(TT2Error.missingData); return }
        initiate(store: store, completion: completion)
    }

    // MARK: Setters
    public func set(mapManager: IMapManager?) {
      tt2Internal.mapManager = mapManager
      tt2Internal.mapManager?.set(isPositionActive: tt2Internal.navigation.isActive)
    }

    public func set(map: IMapController?) {
        tt2Internal.mapController = map
        setupMap()
    }

    public func set(wifi: IWiFiController?) {
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
            let zones = try? self?.zonesTree.getZonesForCurrentFloorLevel(),
            let zone = zones.first(where: { $0.navigationPoints[info.bssid] != nil }),
            let point = zone.navigationPoints.first(where: { $0.key == info.bssid })?.value.point
          else { return }

          self?.tt2Internal.navigation.currentAccessPointPosition = point
        }).store(in: &wifiCancellable)
    }

    func setupMap(changedFloor: Bool = false) {
      guard
        let id = try? activeFloor.id,
        let mapData = mapData,
        let zones = try? zonesTree.getZonesFor(floorLevelId: id)?.filter({ $0.properties.zoneType != "EXPOSURE_POINT" })
      else { return }

      tt2Internal.mapController?.loadMap(with: mapData)
      tt2Internal.mapController?.setup(
        pathfinder: try? tt2Internal.floorManager.getActivePathfinder.invoke(),
        zones: zones,
        sharedProperties: try? tt2Internal.floorManager.getActiveMapZones.invoke()?.sharedProperties,
        shelves: (try? tt2Internal.floorManager.getActiveShelfGroups.invoke()) ?? [],
        changedFloor: changedFloor
      )
    }

    func getHighestHeightDiff(swapLocations: [SwapLocation]) -> Double {
      swapLocations.map { $0.paths.map { $0.heightDiffInMeters } }.flatMap { $0 }.max() ?? 0.0
    }

    func getLowestHeightDiff(swapLocations: [SwapLocation]) -> Double {
      swapLocations.map { $0.paths.map { $0.heightDiffInMeters } }.flatMap { $0 }.min() ?? 0.0
    }

    func setActiveFloor(rtls: RtlsOptions, completion: @escaping () -> ()) {
      setActiveFloor(rtls: rtls)
        .asFailure()
        .sink { _ in
          completion()
        }.store(in: &cancellable)
    }

    func setActiveFloor(rtls: RtlsOptions) -> AnyPublisher<Void, Error> {
      guard
        let storeId = try? activeStore.id,
        let floorHeightDiff = floorHeightDiff
      else { return .fail(with: TT2Error.missingData) }
      tt2Internal.floorManager.setActiveFloor(with: rtls)
      return fetchFloorData(rtls: rtls, storeId: storeId, floorHeightDiff: floorHeightDiff)
    }

    func fetchFloorData(rtls: RtlsOptions, storeId: Int64, floorHeightDiff: Double) -> AnyPublisher<Void, Error> {
      tt2Internal.floorManager.fetchFloorData()
        .handleEvents(receiveOutput: { [weak self] (mapFence, zoneData) in
          guard let self = self else { return }
          setupMapfence(with: mapFence, storeId: storeId, rtlsOptions: rtls, floorHeightDiff: floorHeightDiff)
          mapData = tt2Internal.createMapData(rtlsOptions: rtls, mapFence: mapFence, coordinateConverter: coordinateConverter)
          setupAnalytics(with: zoneData)
        })
        .map { _ in () }
        .eraseToAnyPublisher()
    }

    func setupMapfence(with data: MapFence, storeId: Int64, rtlsOptions: RtlsOptions, floorHeightDiff: Double) {
        guard let converter = coordinateConverter else { return }
        tt2Internal.navigation.vpsPosition.setupMapFence(
            with: data,
            storeId: storeId,
            rtlsOption: rtlsOptions,
            floorheight: floorHeightDiff,
            parameterPackage: positionKitParams,
            automaticSensorRecording: tt2Internal.automaticSensorRecording,
            positionServiceSettings: tt2Internal.activeStore?.positionServiceSettings,
            converter: converter,
            modelManger: tt2Internal.mlModelManager,
            engine: .indoor
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
            try? zonesTree.add(rtls, value.mapZones, value.mapZonesPoints)
        }

        tt2Internal.analytics.zoneManager.setup()
        tt2Internal.analytics.eventManager.setup()
    }
}
