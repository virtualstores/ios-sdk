//
// VSTT2Manager
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import VSFoundation
import ios_position_kit_sdk
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
    
    // MARK: Private members
    private let config = EnvironmentConfig()
    private var tt2Internal: TT2Internal?
    
    public init() {}
    
    public func initialize(with apiUrl: String, apiKey: String, clientId: Int64, completion: @escaping (Error?) -> ()) {
        config.initCentralServerConnection(with: apiUrl, apiKey: apiKey)
        
        self.tt2Internal = TT2Internal(config: config)
        self.tt2Internal?.getStores(with: clientId, completion: { stores in
            completion(nil)
        })
    }
    
    public func setBackgroundAccess(isActive: Bool) {
        navigation.positionKitManager.setBackgroundAccess(isActive: isActive)
    }
    
    public func initiateStore(store: TT2Store, completion: @escaping (Error?) -> ()) {
        ///check
        guard let currentStore = tt2Internal?.internalStores.first(where: { $0.id == store.id }) else { return }
        
        self.activeStore = store
        self.floor.setupFloors(with: currentStore.rtlsOptions)
        
        for rtlsOption in currentStore.rtlsOptions {
            if rtlsOption.isDefault {
                self.setActiveFloor(rtls: rtlsOption) { (error) in
                    completion(error)
                }
            }
        }

        if rtlsOption == nil {
            guard let rtls = currentStore.rtlsOptions.first else { return }
            self.setActiveFloor(rtls: rtls) { (error) in
                completion(error)
            }
        }
        
        setupAnalytics(for: currentStore)
        tt2Internal?.getShelfGroups(for: store.id, activeFloor: self.rtlsOption, completion: { [weak self]
            shelfGroups in
            self?.position.setup(with: shelfGroups)
        })
    }
    
    public func getMapData() -> MapData? {
        mapData
    }
}

private extension TT2 {
    private func setActiveFloor(rtls: RtlsOptions, completion: @escaping (Error?) -> ()) {
        self.rtlsOption = rtls
        self.floor.setActiveFloor(with: rtls) { [weak self] (mapFence, zones, points) in
            if let mapFence = mapFence {
                self?.mapData = self?.tt2Internal?.createMapData(rtlsOptions: rtls, mapFence: mapFence, coordinateConverter: self?.coordinateConverter)
                self?.setupMapfence(with: mapFence)
            }

            self?.setupAnalytics(for: zones, points: points)
            completion(nil)
        }
    }

    private func setupMapfence(with data: MapFence) {
        guard let rtlsOption = self.rtlsOption, let name = self.activeStore?.name else { return }
        
        let converter = BaseCoordinateConverter(heightInPixels: data.properties.height, widthInPixels: data.properties.width, pixelPerMeter: rtlsOption.pixelsPerMeter, pixelPerLatitude: 1000.0)
        
        self.coordinateConverter = converter
        
        self.mapZonesTree = Tree(root: Zone(id: UUID().uuidString, name: name, floorLevel: rtlsOption.floorLevel, converter: converter), converter: converter, currentFloorLevel: rtlsOption.floorLevel)
        
        self.navigation.positionKitManager.setupMapFence(with: data, rtlsOption: rtlsOption)
    }
    
    private func setupAnalytics(for store: Store) {
        let analyticsConfig = EnvironmentConfig()
        guard let serverAddress = store.statServerConnection.serverAddress, let apiKey = store.statServerConnection.apiKey else { return }
        
        analyticsConfig.initCentralServerConnection(with: "\(serverAddress)/api/v2", apiKey: apiKey)
        analytics.setup(with: store, rtlsOptionId: self.rtlsOption?.id, config: analyticsConfig)
    }
    
    private func setupAnalytics(for zones: [Int: [MapZone]]?, points: [Int: [MapZonePoint]]?) {
        guard let rtlsOption = rtlsOption, let store = activeStore, let zones = zones else { return }

        zones.forEach { (key, value) in
            guard let zonePoints = points?[key] else { return }

            mapZonesTree?.add(key, store.name, value, zonePoints)
        }
        
        self.mapZonesTree?.print()
        guard let mapZones = self.mapZonesTree?.getZonesFor(floorLevel: rtlsOption.floorLevel) else { return }
        
        analytics.zoneManager.setup(with: mapZones, rtlsOptions: rtlsOption)
        analytics.evenManager.setup(with: store.id, zones: mapZones, rtlsOptionsId: rtlsOption.id, config: config)
    }
}
