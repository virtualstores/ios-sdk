//
// NetworkManager
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation
import Combine

/// MockManager will use this protocol as well
/// And we will inject MockManager or NetworkManager depended how we want to test
protocol DataHandler {
    func fetch<T: Decodable, R: Routing>(_ routing: R) -> AnyPublisher<T, Error>
    func fetchEmptyBody<R: Routing>(_ routing: R) -> AnyPublisher<Void, Error>
}

final class NetworkManager: DataHandler {

    init() {}

    func fetch<T: Decodable, R: Routing>(_ routing: R) -> AnyPublisher<T, Error> {
        let urlSession = URLSession(configuration: .default)

        guard let url = routing.urlRequest else {
            fatalError("Could not create url")
        }

        return urlSession.dataTaskPublisher(for: url)
            .mapError { $0 as Error }
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    func fetchEmptyBody<R: Routing>(_ routing: R) -> AnyPublisher<Void, Error> {
        let urlSession = URLSession(configuration: .default)

        guard let url = routing.urlRequest else {
            fatalError("Could not create url")
        }

        return urlSession.dataTaskPublisher(for: url)
            .tryMap { element -> Void in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                          throw URLError(.badServerResponse)
                      }
                return Void()

            }.mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
