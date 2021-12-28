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
    public var stepCountPublisher: CurrentValueSubject<Int, Never> = .init(0)

    // MARK: Private members
    private let context = Context(VSTT2Config())
    private var cancellable = Set<AnyCancellable>()
    private var publisherCancellable: AnyCancellable?
    private var positionManager: PositionManager?

    @Inject var clientsListService: ClientsListService
    @Inject var storesListService: StoresListService
    @Inject var mapFenceDataService: MapFenceDataService

    public init() {
        bindPublishers()
    }

    /// Just testing some API calles to be sure that the flow is working
    /// After will add logic where we need have each API call
    public func start() throws {
        positionManager = PositionManager()
        try positionManager?.start()

        getClients()
    }

    public func stop() {
        positionManager?.stop()
        publisherCancellable?.cancel()
    }

    public func setBackgroundAccess(isActive: Bool) {
        positionManager?.setBackgroundAccess(isActive: isActive)
    }

    private func bindPublishers() {
        publisherCancellable = positionManager?.stepCountPublisher
            .sink { [weak self] count in
                self?.stepCountPublisher.send(completion: count)
            } receiveValue: { [weak self]  data in
                self?.stepCountPublisher.send(data)
            }
    }

    deinit {
        stop()
    }
}

// MARK: API calles
private extension VSTT2Manager {
    private func getClients() {
        let parameters = ClientsListParameters()
        clientsListService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { [weak self] (data) in
                guard let clientId = data.clients.first?.clientId else { return }

                self?.getStores(with: clientId)
            }).store(in: &cancellable)
    }

    private func getStores(with clientId: String) {
        let parameters = StoresListParameters(clientId: clientId)
        storesListService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { [weak self] (data) in
                // For now just using 4th element as we know it's the one we can test
                guard let url = data.stores[4].rtlsOptions.mapFenceUrl else { return }

                self?.getMapFenceData(with: url)
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

                do {
                    try self.positionManager?.setupMapFence(with: data)
                    self.positionManager?.startNavigation(with: 180, xPosition: 4.570476, yPosition: 2.094637)

                } catch {
                    // Add error handling logic when MapFence setup failed
                }
            }).store(in: &cancellable)
    }
}
