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

final public class TT2: ITT2 {
    private let context = Context(VSTT2Config())
    
    public var stores: [TT2Store] {
        guard let stores = tt2Internal?.internalStores else { fatalError("tt2Internal is not initialized")}
        
        return stores.map({ $0.toTT2Store() })
    }
    
    public var activeStores: [TT2Store] {
        guard let stores = tt2Internal?.internalStores else { fatalError("tt2Internal is not initialized")}
        
        return stores.filter({ $0.active }).map({ $0.toTT2Store() })
    }
    
    public var navigation: Navigation {
        guard let navigation = tt2Internal?.navigation else { fatalError("tt2Internal is not initialized") }
        
        return navigation
    }
    
    public var analytics: TT2AnalyticsManager {
        guard let analytics = tt2Internal?.analytics else { fatalError("tt2Internal is not initialized") }
        
        return analytics
    }
    
    public var floor: VSTT2FloorManager {
        guard let floor = tt2Internal?.floorManager else { fatalError("tt2Internal is not initialized") }
        
        return floor
    }
    
    public var position: Position {
        guard let position = tt2Internal?.position else { fatalError("tt2Internal is not initialized") }
        
        return position
    }

    public var events: TT2EventManager {
        analytics.eventManager
    }
    
    public var userSettings: UserSettings {
        guard let user = tt2Internal?.user else { fatalError("tt2Internal is not initialized") }
        
        return user
    }

    public private(set) var activeStore: TT2Store?
    public private(set) var activeFloor: RtlsOptions?
    
    public private(set) var coordinateConverter: ICoordinateConverter?
    public private(set) var mapData: MapData?
    public private(set) var map: Map?
    public private(set) var mapZonesTree: Tree?

    // Only for testing purpose of floorchange. Will be removed once green lighted
    public var floorChangePublisher: CurrentValueSubject<String?, Never> = .init(nil)
    
    // MARK: Private members
    private let config = EnvironmentConfig()
    private var tt2Internal: TT2Internal?
    private var floorHeightDiff: Double?

    private var switchFloorCancellable: AnyCancellable?
    
    public init() {}

    public func initialize(with apiUrl: String, apiKey: String, clientId: Int64, completion: @escaping (Error?) -> ()) {
        config.initCentralServerConnection(with: apiUrl, endPoint: .v1, apiKey: apiKey)

        self.tt2Internal = TT2Internal(config: config)
        self.tt2Internal?.getClients(completion: { (error) in
            if let error = error {
                completion(error)
                return
            }
            self.tt2Internal?.getStores(with: clientId, completion: { error in
                completion(error)
            })
        })
    }
    
    public func setMap(map: IMapController) {
        self.tt2Internal?.mapController = map
        self.setupMap()
    }
    
    public func initiateStore(store: TT2Store, completion: @escaping (Error?) -> ()) {
        ///check
        guard let currentStore = tt2Internal?.internalStores.first(where: { $0.id == store.id }) else { return }
        
        self.activeStore = store
        self.floor.setupFloors(with: currentStore.rtlsOptions)

        tt2Internal?.getSwapLocations(for: currentStore.id, completion: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let swapLocations):
              self.floorHeightDiff = self.getHighestHeightDiff(swapLocations: swapLocations)

              let group = DispatchGroup()
              group.enter()
              for rtlsOption in currentStore.rtlsOptions {
                  if rtlsOption.isDefault {
                      self.setActiveFloor(rtls: rtlsOption) { (error) in
                          completion(error)
                          self.mapData?.swapLocations = swapLocations
                          group.leave()
                      }
                  }
              }

              if self.activeFloor == nil {
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
              self.tt2Internal?.getShelfGroups(for: currentStore.id, activeFloor: self.activeFloor) { [weak self] shelfGroups in
                  guard let config = self?.config else { return }
                  self?.position.setup(with: shelfGroups, config: config, store: currentStore)
                  group.leave()
              }
              if let client = self.tt2Internal?.internalClients.first(where: { $0.clientId == currentStore.clientId }) {
                  self.tt2Internal?.accuracyUploader = AccuracyUploader(store: currentStore, connection: self.config.centralServerConnection, client: client)
              }

              group.notify(queue: .main) {
                  self.setupMap()
              }
            case .failure(let error): completion(error)
            }
        })

        setupAnalytics(for: currentStore)
    }
    
    public func getMapData() -> MapData? {
        return self.mapData
    }

    public func startMap() {
        tt2Internal?.mapController?.start()
    }

    public func stop() {
        navigation.stop()
        analytics.stopVisit()
        tt2Internal?.mapController?.stop()
    }
    
    deinit {
        switchFloorCancellable?.cancel()
    }
}

private extension TT2 {
    private func bindPublishers() {
        switchFloorCancellable = floor.switchFloorPublisher
          .compactMap { $0 }
          .sink(receiveValue: { (data) in
              self.navigation.changeFloorStop()
              self.setActiveFloor(rtls: data.rtlsOptions) { (error) in
                  if let error = error {
                      Logger(verbosity: .critical).log(message: "Floor change failed: \(error.localizedDescription)")
                  } else {
                      self.setupMap(changedFloor: true)
                      do {
                          try self.navigation.changeFloorStart(startPosition: data.point)
                          self.floorChangePublisher.send(data.rtlsOptions.name)
                      } catch {
                          Logger(verbosity: .critical).log(message: "Starting on new floor failed")
                      }
                  }
              }
          })
    }

    private func setupMap(changedFloor: Bool = false) {
      guard
        let rtls = activeFloor,
        let mapData = mapData,
        let converter = coordinateConverter,
        let navData = floor.navgraph,
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
      let sharedProperties = floor.zoneData[rtls.floorLevel]?.sharedProperties
      self.tt2Internal?.mapController?.setup(pathfinder: pathfinder, zones: zones, sharedProperties: sharedProperties, changedFloor: changedFloor)

      self.tt2Internal?.mapController?.loadMap(with: mapData)
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

    private func setActiveFloor(rtls: RtlsOptions, completion: @escaping (Error?) -> ()) {
        guard let floorHeightDiff = floorHeightDiff else { return }
        self.activeFloor = rtls
        self.floor.setActiveFloor(with: rtls) { [weak self] (mapFence, zoneData) in
            if let mapFence = mapFence {
              self?.setupMapfence(with: mapFence, floorHeightDiff: 0.5/*floorHeightDiff*/)
                self?.mapData = self?.tt2Internal?.createMapData(rtlsOptions: rtls, mapFence: mapFence, coordinateConverter: self?.coordinateConverter)
            }

            self?.setupAnalytics(with: zoneData)
            completion(nil)
        }
    }

    private func setupMapfence(with data: MapFence, floorHeightDiff: Double) {
        guard let rtlsOption = self.activeFloor, let name = self.activeStore?.name else { return }
        
        let converter = BaseCoordinateConverter(heightInPixels: data.properties.height, widthInPixels: data.properties.width, pixelPerMeter: rtlsOption.pixelsPerMeter, pixelPerLatitude: 1000.0)
        
        self.coordinateConverter = converter

        let properties = ZoneProperties(description: nil, id: name, name: name, names: [], parentId: nil, fillColor: nil, fillColorSelected: nil, lineColor: nil, lineColorSelected: nil)
        self.mapZonesTree = Tree(root: Zone(id: UUID().uuidString, properties: properties, floorLevelId: rtlsOption.id, converter: converter), converter: converter, currentFloorLevelId: rtlsOption.id)

        #if DEBUG
        let shouldRecord = false
        #else
        let shouldRecord = false
        #endif

        self.navigation.positionKitManager.setupMapFence(with: data, rtlsOption: rtlsOption, floorheight: floorHeightDiff, shouldRecord: shouldRecord)
    }
    
    private func setupAnalytics(for store: Store) {
        let analyticsConfig = EnvironmentConfig()
        guard let serverAddress = store.statServerConnection.serverAddress, let apiKey = store.statServerConnection.apiKey else { return }
        
        analyticsConfig.initCentralServerConnection(with: serverAddress, endPoint: .v2, apiKey: apiKey)
        analytics.setup(with: store, rtlsOptionId: self.activeFloor?.id, config: analyticsConfig)
    }
    
    private func setupAnalytics(with zoneData: [Int: ZoneData]?) {
        guard let rtlsOption = activeFloor, let store = activeStore, let zoneData = zoneData else { return }

        zoneData.forEach { (key, value) in
            guard let rtls = floor.floors.first(where: { $0.floorLevel == key }) else { return }
            mapZonesTree?.add(rtls, value.mapZones, value.mapZonesPoints)
        }

        mapZonesTree?.print()
        guard let mapZones = self.mapZonesTree?.getZonesFor(floorLevelId: rtlsOption.id) else { return }

        analytics.update(rtlsOptionId: rtlsOption.id)
        analytics.zoneManager.setup(with: mapZones, rtlsOptions: rtlsOption)
        analytics.eventManager.setup(with: store.id, zones: mapZones, rtlsOptionsId: rtlsOption.id, config: config)
    }
}
