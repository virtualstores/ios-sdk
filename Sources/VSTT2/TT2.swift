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
    
    public var userSettings: UserSettings {
        guard let user = tt2Internal?.user else { fatalError("tt2Internal is not initialized") }
        
        return user
    }
    
    public var activeStore: TT2Store?
    
    public var coordinateConverter: ICoordinateConverter?
    public var mapData: MapData?
    public var map: Map?
    public var rtlsOption: RtlsOptions?
    public var mapZonesTree: Tree?

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
              for rtlsOption in currentStore.rtlsOptions {
                  if rtlsOption.isDefault {
                      self.setActiveFloor(rtls: rtlsOption) { (error) in
                          completion(error)
                      }
                  }
              }

              if self.rtlsOption == nil {
                  guard let rtls = currentStore.rtlsOptions.first else { return }
                  self.setActiveFloor(rtls: rtls) { (error) in
                      completion(error)
                  }
              }

              self.floor.setup(swapLocations: swapLocations)
              self.bindPublishers()
              self.tt2Internal?.getShelfGroups(for: currentStore.id, activeFloor: self.rtlsOption) { [weak self] shelfGroups in
                  guard let config = self?.config else { return }
                  self?.position.setup(with: shelfGroups, config: config, store: currentStore)
              }
              if let client = self.tt2Internal?.internalClients.first(where: { $0.clientId == currentStore.clientId }) {
                  self.tt2Internal?.accuracyUploader = AccuracyUploader(store: currentStore, connection: self.config.centralServerConnection, client: client)
              }
            case .failure(let error): completion(error)
            }
        })

        setupAnalytics(for: currentStore)
    }
    
    public func getMapData(mapStyle: MapStyle) -> MapData? {
        self.mapData?.style = mapStyle
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
        self.rtlsOption = rtls
        self.floor.setActiveFloor(with: rtls) { [weak self] (mapFence, zones, points) in
            if let mapFence = mapFence {
                self?.setupMapfence(with: mapFence, floorHeightDiff: floorHeightDiff)
                self?.mapData = self?.tt2Internal?.createMapData(rtlsOptions: rtls, mapFence: mapFence, coordinateConverter: self?.coordinateConverter)
            }

            self?.setupAnalytics(for: zones, points: points)
            completion(nil)
        }
    }

    private func setupMapfence(with data: MapFence, floorHeightDiff: Double) {
        guard let rtlsOption = self.rtlsOption, let name = self.activeStore?.name else { return }
        
        let converter = BaseCoordinateConverter(heightInPixels: data.properties.height, widthInPixels: data.properties.width, pixelPerMeter: rtlsOption.pixelsPerMeter, pixelPerLatitude: 1000.0)
        
        self.coordinateConverter = converter
        
        self.mapZonesTree = Tree(root: Zone(id: UUID().uuidString, name: name, floorLevel: rtlsOption.floorLevel, converter: converter), converter: converter, currentFloorLevel: rtlsOption.floorLevel)

        #if DEBUG
        let shouldRecord = true
        #else
        let shouldRecord = false
        #endif

        self.navigation.positionKitManager.setupMapFence(with: data, rtlsOption: rtlsOption, floorheight: floorHeightDiff, shouldRecord: shouldRecord)
    }
    
    private func setupAnalytics(for store: Store) {
        let analyticsConfig = EnvironmentConfig()
        guard let serverAddress = store.statServerConnection.serverAddress, let apiKey = store.statServerConnection.apiKey else { return }
        
        analyticsConfig.initCentralServerConnection(with: serverAddress, endPoint: .v2, apiKey: apiKey)
        analytics.setup(with: store, rtlsOptionId: self.rtlsOption?.id, config: analyticsConfig)
    }
    
    private func setupAnalytics(for zones: [Int: [MapZone]]?, points: [Int: [MapZonePoint]]?) {
        guard let rtlsOption = rtlsOption, let store = activeStore, let zones = zones else { return }

        zones.forEach { (key, value) in
            guard let zonePoints = points?[key] else { return }

            mapZonesTree?.add(key, store.name, value, zonePoints)
        }

        guard let mapZones = self.mapZonesTree?.getZonesFor(floorLevel: rtlsOption.floorLevel) else { return }

        analytics.update(rtlsOptionId: rtlsOption.id)
        analytics.zoneManager.setup(with: mapZones, rtlsOptions: rtlsOption)
        analytics.evenManager.setup(with: store.id, zones: mapZones, rtlsOptionsId: rtlsOption.id, config: config)
    }
}
