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

final public class VSTT2Manager: VSTT2 {
    public var availableStores: CurrentValueSubject<StoresList?, VSTT2Error> = .init(nil)
    public var mapFanceDataExistPublisher: CurrentValueSubject<MapFence?, Never> = .init(nil)
    
    // MARK: Private members
    private let context = Context(VSTT2Config())
    private var cancellable = Set<AnyCancellable>()
    private var activeStore: Store?
    private var swapLocations: [SwapLocation] = []
    
    /// Services for getting the api data
    @Inject var storesListService: StoresListService
    @Inject var swapLocationsService: SwapLocationsService
    @Inject var ordersService: OrdersService
    @Inject var itemPositionService: ItemPositionService
    @Inject var shelfGroupService: ShelfGroupService
    
    /// Managers for helping VSTT to work with separate small modules
    @Inject public var tt2PositionManager: TT2PositionManager
    @Inject public var analyticsManager: TT2AnalyticsManager
    @Inject var floorManager: VSTT2FloorManager

    public var coordinateConverter: ICoordinateConverter?
    public var shelfGroups: [ShelfGroup]?
    public var map: Map?
    public var rtlsOption: RtlsOptions?
    private var publisherCancellable: AnyCancellable?
    private var flooreCancellable: AnyCancellable?
    private var flooreMapDataCancellable: AnyCancellable?
    public var mapZonesTree: Tree?
    
    public init(with apiUrl: String? = nil, apiKey: String? = nil, clientId: Int64) {
        self.getStores(with: clientId)
        
        tt2PositionManager.setupAnalyticsManager(manager: analyticsManager)
    }
    
    public func setBackgroundAccess(isActive: Bool) {
        tt2PositionManager.positionKitManager.setBackgroundAccess(isActive: isActive)
    }
    
    public func initiateStore(store: Store) {
        self.activeStore = store
        self.floorManager.setupFloors(with: store.rtlsOptions)
        
        for rtlsOption in store.rtlsOptions {
            if rtlsOption.isDefault {
                self.rtlsOption = rtlsOption
                self.floorManager.setActiveFloor(with: rtlsOption)
            }
        }
        
        analyticsManager.setup(with: store, rtlsOptionId: self.rtlsOption?.id)
        
        getShelfGroups()
        bindPublishers()
    }
    
    public func createMapData(rtlsOptions: RtlsOptions, mapFence: MapFence) -> MapData? {
        guard let converter = self.coordinateConverter else { return nil }
        
        let image = UIImage(named: "userMarker")
        let mapData = MapData(rtlsOptions: rtlsOptions, style: MapStyle(userMarkerImage: image), converter: converter)
        
        return mapData
    }
    
    private func bindPublishers() {
        //TODO: create flooreManager publisher and use for getting SwapLocations
        //        publisherCancellable = navigationManager.navigationSpacePublisher
        //            .sink { _ in
        //                Logger.init(verbosity: .debug).log(message: "Navigation Space Publisher error")
        //            } receiveValue: { [weak self] _ in
        //                guard let self = self, let id = self.activeStore?.id else { return }
        //
        //                if self.swapLocations.isEmpty {
        //                    self.getSwapLocations(for: id)
        //                }
        //            }
        
        flooreMapDataCancellable = floorManager.mapDataPublisher
            .sink { _ in
                Logger.init(verbosity: .debug).log(message: "Floor Data Loaded Publisher error")
            } receiveValue: { [weak self] (mapfence, zones, points) in
                guard let mapfence = mapfence, let zones = zones else { return }
                
                self?.setupMapfence(with: mapfence)
                self?.mapFanceDataExistPublisher.send(mapfence)
                self?.setupAnalytics(for: zones, points: points)
            }
    }
    
    private func setupMapfence(with data: MapFence) {
        guard let rtlsOption = self.rtlsOption, let name = self.activeStore?.name else { return }
        
        let converter = BaseCoordinateConverter(heightInPixels: data.properties.height, widthInPixels: data.properties.width, pixelPerMeter: rtlsOption.pixelsPerMeter, pixelPerLatitude: 1000.0)
        
        self.coordinateConverter = converter
        
        self.mapZonesTree = Tree(root: Zone(id: UUID().uuidString, name: name, floorLevel: rtlsOption.floorLevel, converter: converter), converter: converter, currentFloorLevel: rtlsOption.floorLevel)
        
        self.tt2PositionManager.positionKitManager.setupMapFence(with: data, rtlsOption: rtlsOption)
    }
    
    private func setupAnalytics(for zones: [MapZone]?, points: [MapZonePoint]?) {
        guard let rtlsOption = rtlsOption, let store = activeStore, let zones = zones else { return }
        
        mapZonesTree?.add(rtlsOption.floorLevel, store.name, zones, points ?? [])
        
        self.mapZonesTree?.print()
        guard let mapZones = self.mapZonesTree?.getZonesFor(floorLevel: rtlsOption.floorLevel) else { return }
        
        analyticsManager.zoneManager.setup(with: mapZones, rtlsOptions: rtlsOption)
        analyticsManager.evenManager.setup(with: store.id, zones: mapZones, rtlsOptionsId: rtlsOption.id)
    }
}

// MARK: API calles
private extension VSTT2Manager {
    private func getStores(with clientId: Int64) {
        let parameters = StoresListParameters(clientId: clientId)
        storesListService
            .call(with: parameters)
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self?.availableStores.send(completion: .failure(VSTT2Error.noAvailableStores))
                }
            }, receiveValue: { [weak self] (data) in
                self?.availableStores.send(data)
            }).store(in: &cancellable)
    }
    
    private func getSwapLocations(for storeId: Int64) {
        let swapLocationsParameters = SwapLocationsParameters(storeId: storeId)
        
        swapLocationsService
            .call(with: swapLocationsParameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] (swapLocations) in
                self?.swapLocations = swapLocations
            }).store(in: &cancellable)
    }
    
    /// move this methode in manager where needed
    /// now it's here just for testing the API
    func postOrders(storeId: Int64, orderIds: [String], device: DeviceInformation) {
        let parameters = OrdersParameters(storeId: storeId, orderIds: orderIds, deviceInformation: device)
        
        ordersService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: {_ in
                
            }).store(in: &cancellable)
    }
    
    func getItemPosition(storeId: Int64, itemId: String) {
        let parameters = ItemPositionParameters(storeId: storeId, barcode: itemId)
        
        itemPositionService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { data in
                print(data)
            }).store(in: &cancellable)
    }
    
    private func getShelfGroups() {
        guard let activeStore = self.activeStore else { return }
        
        let shelfGroupParameters = ShelfGroupParameters(storeId: activeStore.id)
        
        shelfGroupService
            .call(with: shelfGroupParameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { [weak self] (shelfData) in
                guard let activeFloor = self?.rtlsOption else { return }
                
                let shelfGroups = shelfData.map({ ShelfGroupDto.toShelfGroup($0) })
                
                self?.map = Map(id: activeStore.id, mapURL: activeFloor.mapBoxUrl ?? "", storeId: activeStore.id, railScale: 0, pixelOffsetX: Int(activeFloor.startOffsetY), pixelOffsetY: Int(activeFloor.startOffsetY), pixelWidth: Int(activeFloor.rtlsOptionsWidth()), pixelHeight: Int(activeFloor.rtlsOptionsHeight()))
                
                self?.shelfGroups = shelfGroups
            }).store(in: &cancellable)
    }
}
