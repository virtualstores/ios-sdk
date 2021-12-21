//
// VSTT2Manager
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import VSFoundation

final public class VSTT2Manager: VSTT2 {
    // MARK: Private members
    private let clientsListService: ClientsListService
    private let storesListService: StoresListService
    private let mapFenceDataService: MapFenceDataService

    private let context: Context
    private var cancellable = Set<AnyCancellable>()

    public init() {
        context = Context(VSTT2Config())
        clientsListService = ClientsListService(with: NetworkManager())
        storesListService = StoresListService(with: NetworkManager())
        mapFenceDataService = MapFenceDataService(with: NetworkManager())
    }

    /// Just testing some API calles to be sure that the flow is working
    /// After will add logic where we need have each API call
    public func start() {
        getClients()
    }

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
            }, receiveValue: { (data) in
                print(data)
            }).store(in: &cancellable)
    }
}
