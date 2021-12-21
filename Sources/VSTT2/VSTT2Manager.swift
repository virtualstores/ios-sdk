//
// VSTT2Manager
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import Combine

final public class VSTT2Manager: VSTT2 {
    // MARK: Private members
    private let clientsListService: ClientsListService
    private let storesListService: StoresListService

    private var cancellable = Set<AnyCancellable>()

    public init() {
        clientsListService = ClientsListService(with: NetworkManager())
        storesListService = StoresListService(with: NetworkManager())
    }

    /// Just tested 2 API calles to be sure that the flow is working
    public func start() {
        getClients()
    }

    public func stop() {}

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
            }, receiveValue: { (data) in
                print(data)
            }).store(in: &cancellable)
    }
}
