//
// DataFetchingManager
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation
import Combine

class DataFetchingManager {
    /// DataHandler to fetch the data  from real api or mock data
    /// Based on what we have injected
    private let dataHeandler: DataHandler

    init(with dataHeandler: DataHandler) {
        self.dataHeandler = dataHeandler
    }

     func execute<T: Decodable, R: Routing, E: Error>(_ route: R, errorType: E.Type) -> AnyPublisher<T, Error> {
        return dataHeandler.fetch(route)
    }

    func executeEmptyBody<R: Routing, E: Error>(_ route: R, errorType: E.Type) -> AnyPublisher<Void, Error> {
       return dataHeandler.fetchEmptyBody(route)
   }
}
