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
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
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
