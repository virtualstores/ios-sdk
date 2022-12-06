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

        guard let url = routing.urlRequest else { fatalError("Could not create url") }

        let date = Date()
        print("<--", routing.method, url)
        return urlSession.dataTaskPublisher(for: url)
            .mapError { $0 as Error }
            .map { (result) in
              if let response = result.response as? HTTPURLResponse {
//                print("result", response.)
                let timeInterval = Date().timeIntervalSince(date)
                print("-->", response.statusCode, response.url?.absoluteString ?? "", "[\(result.data.count) b]", String(format: "[%.03f s]", timeInterval))
              }
              return result.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    func fetchEmptyBody<R: Routing>(_ routing: R) -> AnyPublisher<Void, Error> {
        let urlSession = URLSession(configuration: .default)

        guard let url = routing.urlRequest else { fatalError("Could not create url") }

        let date = Date()
        print("<--", routing.method, url)
        return urlSession.dataTaskPublisher(for: url)
            .tryMap { element -> Void in
                let timeInterval = Date().timeIntervalSince(date)
                guard let response = element.response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                guard response.statusCode == 200 else {
                  print("-->", response.statusCode, response.url?.absoluteString ?? "", "[\(0) b]", String(format: "[%.03f s]", timeInterval))
                  throw URLError(.badServerResponse)
                }
                print("-->", response.statusCode, response.url?.absoluteString ?? "", "[\(0) b]", String(format: "[%.03f s]", timeInterval))
                return Void()

            }.mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
