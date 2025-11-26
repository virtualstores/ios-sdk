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
  case sessionExpired, invalidTokens
}

final class NetworkManager: DataHandler {

  init() {}

  func fetch<T: Decodable, R: Routing>(_ routing: R) -> AnyPublisher<T, Error> {
    let urlSession = URLSession(configuration: .default)

    guard let url = routing.urlRequest else { return .fail(with: URLError(.badURL)) }

    let date = Date()
    Logger(verbosity: .network).log(message: "<-- \(routing.method) \(url)")
    return urlSession
      .dataTaskPublisher(for: url)
      .mapError { $0 as Error }
      .tryMap { (result) in
        guard let response = result.response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        let timeInterval = Date().timeIntervalSince(date)
        Logger(verbosity: .network).log(message: "--> \(response.statusCode) \(response.url?.absoluteString ?? "") [\(result.data.count) b] \(String(format: "[%.03f s]", timeInterval))")
        guard response.statusCode == 401 else { return result.data }
        throw NetworkError.sessionExpired
      }
      .catch { (error) -> AnyPublisher<Data, Error> in
        if (error as? NetworkError) == .sessionExpired {
          @Inject var refresh: RefreshUseCase
          return refresh.invoke()
            .flatMap { (_) in self.fetch(routing) }
            .eraseToAnyPublisher()
        } else {
          return .fail(with: error)
        }
      }
      .decode(type: T.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
  }

  func fetchEmptyBody<R: Routing>(_ routing: R) -> AnyPublisher<Void, Error> {
    let urlSession = URLSession(configuration: .default)

    guard let url = routing.urlRequest else {
      return Fail<Void, Error>(error: URLError(.badURL))
        .eraseToAnyPublisher()
    }

    let date = Date()
    Logger(verbosity: .network).log(message: "<-- \(routing.method) \(url)")
    return urlSession.dataTaskPublisher(for: url)
      .tryMap { element -> Void in
        guard let response = element.response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        let timeInterval = Date().timeIntervalSince(date)
        Logger(verbosity: .network).log(message: "--> \(response.statusCode) \(response.url?.absoluteString ?? "") [\(0) b] \(String(format: "[%.03f s]", timeInterval))")
        switch response.statusCode {
        case 200..<300: return ()
        case 401: throw NetworkError.sessionExpired
        default: throw URLError(.badServerResponse)
        }
      }
      .catch { (error) -> AnyPublisher<Void, Error> in
        if (error as? NetworkError) == .sessionExpired {
          @Inject var refresh: RefreshUseCase
          return refresh.invoke()
            .flatMap { (_) in self.fetchEmptyBody(routing) }
            .eraseToAnyPublisher()
        } else {
          return .fail(with: error)
        }
      }
      .mapError { $0 as Error }
      .eraseToAnyPublisher()
  }
}
