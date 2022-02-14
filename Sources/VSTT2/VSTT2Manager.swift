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

final public class VSTT2Manager: VSTT2 {
    public var availableStores: CurrentValueSubject<StoresList?, VSTT2Error> = .init(nil)
    public var mapFanceDataExistPublisher: CurrentValueSubject<MapFence?, Never> = .init(nil)

    // MARK: Private members
    private let context = Context(VSTT2Config())
    private var cancellable = Set<AnyCancellable>()
    private var isMapFunctionalityAvailable: Bool
    private var activeStore: Store?
    private var swapLocations: [SwapLocation] = []

    @Inject var positionManager: PositionManager
    @Inject var mapFenceDataService: MapFenceDataService
    @Inject var storesListService: StoresListService
    @Inject var swapLocationsService: SwapLocationsService
    @Inject var ordersService: OrdersService
    @Inject var itemPositionService: ItemPositionService
    @Inject public var tt2PositionManager: TT2PositionManager
    @Inject var navigationManager: TT2NavigationManager

    private var publisherCancellable: AnyCancellable?

    public init(with apiUrl: String? = nil, apiKey: String? = nil, clientId: Int64, isMapAvailable: Bool = true) {
        self.isMapFunctionalityAvailable = isMapAvailable

        self.getStores(with: clientId)
    }

    public func setBackgroundAccess(isActive: Bool) {
        positionManager.setBackgroundAccess(isActive: isActive)
    }

    public func initiateStore(store: Store, floorLevel: Int) {
        self.activeStore = store
        tt2PositionManager.configureStoreData(for: store, floorLevel: floorLevel)
        initiateStore(with: store)
        
        guard let url = store.rtlsOptions.first?.mapFenceUrl else { return }

      //  getMapFenceData(with: url)
        
        bindPublishers()
    }

    func initiateStore(with store: Store) {
        navigationManager.prepareNavigationSpace(for: store)
    }

    private func bindPublishers() {
        publisherCancellable = navigationManager.navigationSpacePublisher
            .sink { _ in
                Logger.init(verbosity: .debug).log(message: "Navigation Space Publisher error")
            } receiveValue: { [weak self] _ in
                guard let self = self, let id = self.activeStore?.id else { return }

                if self.swapLocations.isEmpty {
                    self.getSwapLocations(for: id)
                }
        }
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
    
    private func getMapFenceData(with url: String) {
        let parameters = MapFenceDataParameters(url: url)
        mapFenceDataService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { [weak self] (data) in
                guard let self = self else { return }
                
               // self.currentMapFence = data
                self.positionManager.setupMapFence(with: data)
                self.mapFanceDataExistPublisher.send(data)
            }).store(in: &cancellable)
    }
}
