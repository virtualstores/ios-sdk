//
// DownloadManager
// VSTT2
//
// Created by Hripsime on 2022-01-22
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import SwiftUI
import VSFoundation

final class DownloadManager {
    func loadData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let date = Date()
        print("<--", "GET", url)
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                if let response = response as? HTTPURLResponse {
                    let timeInterval = Date().timeIntervalSince(date)
                    print("-->", response.statusCode, response.url?.absoluteString ?? "", "[\(data.count) b]", String(format: "[%.03f s]", timeInterval))
                }
                completion(.success(data))
            } else if let error = error {
                completion(.failure(error))
            } else {
                Logger.init().log(message: "loadData error")
            }
        }
        
        task.resume()
    }

    @available(iOS 15.0.0, *)
    func downloadData(from url: URL) async throws -> Data {
        let request = URLRequest.init(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

        return data
    }
}
