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
    private let clientsListService: ClientsListService
    private let storesListService: StoresListService
    private let mapFenceDataService: MapFenceDataService
    private var positionManager: PositionManager?

    private let context: Context
    private var cancellable = Set<AnyCancellable>()
    private var publisherCancellable: AnyCancellable?

    public init() {
        context = Context(VSTT2Config())

        clientsListService = ClientsListService(with: NetworkManager())
        storesListService = StoresListService(with: NetworkManager())
        mapFenceDataService = MapFenceDataService(with: NetworkManager())

        bindPublishers()
    }

    /// Just testing some API calles to be sure that the flow is working
    /// After will add logic where we need have each API call
    public func start() throws {
        // maybe we need call positionManager?.start() after positionManager will be initialized
        try positionManager?.start()

        getClients()
    }

    public func stop() {
        positionManager?.stop()
    }

    public func setBackgroundAccess(isActive: Bool) {
        positionManager?.setBackgroundAccess(isActive: isActive)
    }

    private func bindPublishers() {
        publisherCancellable = positionManager?.stepCountPublisher
            .sink { [weak self] count in
                self?.stepCountPublisher.send(completion: count)
            } receiveValue: { data in
                self.stepCountPublisher.send(data)
            }
    }

    deinit {
        publisherCancellable?.cancel()
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
                guard let url = data.stores.first?.rtlsOptions.mapFenceUrl else { return }

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
                self?.positionManager = PositionManager(with: data)
            }).store(in: &cancellable)
    }
}
