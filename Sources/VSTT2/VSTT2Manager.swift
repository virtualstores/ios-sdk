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
    // MARK: Private members
    private let context = Context(VSTT2Config())
    private var cancellable = Set<AnyCancellable>()
    private var isMapFunctionalityAvailable: Bool
    private var activeStore: Store?
    
    @Inject var positionManager: PositionManager
    @Inject var storesListService: StoresListService
    @Inject var tt2PositionManager: TT2PositionManager

    public init(with apiUrl: String? = nil, apiKey: String? = nil, clientId: String, isMapAvailable: Bool = true) {
        self.isMapFunctionalityAvailable = isMapAvailable

        self.getStores(with: clientId)
    }

    public func setBackgroundAccess(isActive: Bool) {
        positionManager.setBackgroundAccess(isActive: isActive)
    }
    
    public func initiateStore(store: Store, floorLevel: Int) {
        self.activeStore = store
        tt2PositionManager.configureStoreData(for: store, floorLevel: floorLevel)
    }
}

// MARK: API calles
private extension VSTT2Manager {
    private func getStores(with clientId: String) {
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
}
