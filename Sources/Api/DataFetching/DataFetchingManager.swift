//
// DataFetchingManager
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021


import Foundation
import Combine

class DataFetchingManager {
    /// Network manager to fetch the data 
    /// Will be injected with constructor injection,(can be used Injector from VSFoundation)
    let networkManager: NetworkManager

    init(with networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func execute<T: Decodable, R: Routing, E: Error>(_ route: R, errorType: E.Type) -> AnyPublisher<T, Error> {

        return self.networkManager.fetch(route)
    }
}
