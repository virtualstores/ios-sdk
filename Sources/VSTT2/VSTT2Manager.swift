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
    public var stepCountPublisher: CurrentValueSubject<Int, Never> = .init(0)
    public var positionBundlePublisher: CurrentValueSubject<PositionBundle?, PositionKitError> = .init(nil)

    // MARK: Private members
    private let context = Context(VSTT2Config())
    private var cancellable = Set<AnyCancellable>()
    private var publisherCancellable: AnyCancellable?
    private var positionBundleCancellable: AnyCancellable?
    private var isMapFunctionalityAvailable: Bool

    @Inject var positionManager: PositionManager
    @Inject var clientsListService: ClientsListService
    @Inject var storesListService: StoresListService
    @Inject var mapFenceDataService: MapFenceDataService

    public init(with apiUrl: String? = nil, apiKey: String? = nil, clientId: String, isMapAvailable: Bool = true) {
        self.isMapFunctionalityAvailable = isMapAvailable

        self.getStores(with: clientId)
    }

    public  func start() throws {
        try positionManager.start()
        bindPublishers()
    }

    public func stop() {
        positionManager.stop()
        publisherCancellable?.cancel()
    }

    public func setBackgroundAccess(isActive: Bool) {
        positionManager.setBackgroundAccess(isActive: isActive)
    }

    public func configureStoreData(for store: Store, floorLevelId: String? = nil) {
         guard let url = store.rtlsOptions.mapFenceUrl else { return }

         self.getMapFenceData(with: url)
     }

    private func bindPublishers() {
        publisherCancellable = positionManager.stepCountPublisher
            .sink { [weak self] error in
                self?.stepCountPublisher.send(completion: error)
            } receiveValue: { [weak self]  data in
                self?.stepCountPublisher.send(data)
            }

        positionBundleCancellable = positionManager.positionPublisher
            .sink { [weak self] error in
                self?.positionBundlePublisher.send(completion: error)
            } receiveValue: { [weak self]  positionBundle in
                self?.positionBundlePublisher.send(positionBundle)
            }
    }

    deinit {
        stop()
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

    private func getMapFenceData(with url: String) {
        let parameters = MapFenceDataParameters(url: url)
        mapFenceDataService
            .call(with: parameters)
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self?.availableStores.send(completion: .failure(VSTT2Error.noAvailableMapData))
                }
            }, receiveValue: { [weak self] (data) in
                guard let self = self else { return }

                do {
                    try self.positionManager.setupMapFence(with: data)
                    self.positionManager.startNavigation(with: 180, xPosition: 4.570476, yPosition: 2.094637)

                } catch {
                    // Add error handling logic when MapFence setup failed
                }
            }).store(in: &cancellable)
    }
}
