//
// NetworkManager
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import VSFoundation

/// MockManager will use this protocol as well
/// And we will inject MockManager or NetworkManager depended how we want to test
protocol DataHandler {
  func fetch<T: Decodable, R: Routing>(_ routing: R) -> AnyPublisher<T, Error>
  func fetchEmptyBody<R: Routing>(_ routing: R) -> AnyPublisher<Void, Error>
}

enum NetworkError: Error {
  case invalidURL
  case decodingFailed
  case sessionExpired
}

final class NetworkManager: DataHandler {

  init() {}

  func fetch<T: Decodable, R: Routing>(_ routing: R) -> AnyPublisher<T, Error> {
    let urlSession = URLSession(configuration: .default)

    guard let url = routing.urlRequest else { fatalError("Could not create url") }

    let date = Date()
    print("<--", routing.method, url)
    return urlSession
      .dataTaskPublisher(for: url)
      .mapError { $0 as Error }
      .tryMap { (result) in
        guard let response = result.response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        let timeInterval = Date().timeIntervalSince(date)
        print("-->", response.statusCode, response.url?.absoluteString ?? "", "[\(result.data.count) b]", String(format: "[%.03f s]", timeInterval))
        guard response.statusCode == 401 else { return result.data }
        throw NetworkError.sessionExpired
      }
      .tryCatch { (error) -> AnyPublisher<Data, Error> in
        if (error as? NetworkError) == .sessionExpired {
          @Inject var refresh: RefreshUseCase
          let group = DispatchGroup()
          group.enter()
          refresh.invoke { (error) in
            group.leave()
          }
          group.wait()
          return self.fetch(routing)
        } else {
          throw error
        }
      }
      .decode(type: T.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
  }

  func fetchEmptyBody<R: Routing>(_ routing: R) -> AnyPublisher<Void, Error> {
    let urlSession = URLSession(configuration: .default)
    urlSession.configuration.httpMaximumConnectionsPerHost = 32

    guard let url = routing.urlRequest else { fatalError("Could not create url") }

    let date = Date()
    print("<--", routing.method, url)
    return urlSession.dataTaskPublisher(for: url)
      .tryMap { element -> Void in
        let timeInterval = Date().timeIntervalSince(date)
        guard let response = element.response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        print("-->", response.statusCode, response.url?.absoluteString ?? "", "[\(0) b]", String(format: "[%.03f s]", timeInterval))
        guard 200..<300 ~= response.statusCode else {
          if response.statusCode == 401 {
            throw NetworkError.sessionExpired
          }
          throw URLError(.badServerResponse)
        }
        return Void()
      }
      .tryCatch { (error) -> AnyPublisher<Void, Error> in
        if (error as? NetworkError) == .sessionExpired {
          @Inject var refresh: RefreshUseCase
          let group = DispatchGroup()
          group.enter()
          refresh.invoke { (error) in
            group.leave()
          }
          group.wait()
          return self.fetchEmptyBody(routing)
        } else {
          throw error
        }
      }
      .mapError { $0 as Error }
      .eraseToAnyPublisher()
  }
}
