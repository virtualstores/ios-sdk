//
// DownloadManager
// VSTT2
//
// Created by Hripsime on 2022-01-22
// Copyright Virtual Stores - 2022

import Combine
import Foundation
import VSFoundation

final class DownloadManager {
    func loadData(from url: URL) -> AnyPublisher<Data, Error> {
        let start = Date()
        Logger(verbosity: .network).log(message: "<-- GET \(url)")
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data, response) in
                if let response = response as? HTTPURLResponse {
                    let duration = Date().timeIntervalSince(start)
                    Logger(verbosity: .network).log(message: "--> \(response.statusCode) \(response.url?.absoluteString ?? "") [\(data.count) b] \(String(format: "[%.03f s]", duration))")
                }

                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    throw URLError(.badServerResponse)
                }

                return data
            }
            .eraseToAnyPublisher()
    }

    @available(iOS 15.0.0, *)
    func downloadData(from url: URL) async throws -> Data {
        let request = URLRequest.init(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

        return data
    }
}
