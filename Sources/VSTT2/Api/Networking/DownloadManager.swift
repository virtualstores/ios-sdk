//
// DownloadManager
// VSTT2
//
// Created by Hripsime on 2022-01-22
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import UIKit
import SwiftUI

protocol DownloadManagerServicing {
    func download(from url: URL) -> AnyPublisher<Data?, Error>
    func cancelRequest(of url: URL)
}

final class DownloadManager: DownloadManagerServicing {
    typealias PostDownloadAction = (Data?, Error?) -> Void

    private let queue = DispatchQueue(label: "DownloadManagerQueueId")

    public init() {}

    private var cache: [URL: Data] = [:]
    private var dataRequest: [URL: URLSessionDataTask] = [:]
    private var postDownloadActions: [URL: [PostDownloadAction]] = [:]

    public func download(from url: URL) ->  AnyPublisher<Data?, Error> {
        return Future<Data?, Error> { resolve in

            self.queue.sync {
                if let data = self.cache[url] {
                    #if DEV
                    print("Data returned from cache")
                    #endif
                    resolve(.success(data))

                    return
                }
                // if this statement is true it means we already have a data task in process, so we add case in postDownloadActions and run the actions when the process of downlaoding is done
                if self.dataRequest[url] != nil {
                    var actions: [PostDownloadAction] = self.postDownloadActions[url] ?? []
                    let action: PostDownloadAction = { data, _ in
                        resolve(.success(data))
                    }

                    actions.append(action)

                    self.postDownloadActions[url] = actions

                    return
                }

                let dataTask = URLSession.shared.dataTask(with: url, completionHandler: { (data, _, error) in
                    if let data = data {
                        self.cache[url] = data
                    } else {
                        if let errorData = error {
                            resolve(.failure(errorData))
                        }
                        #if DEV
                        print("Downloaing failed \(error?.localizedDescription ?? "")")
                        #endif
                    }
                    resolve(.success(data))

                    self.dataRequest[url] = nil

                    self.postDownloadActions[url]?.forEach({ action in
                        action(data, error)
                    })

                    self.postDownloadActions[url] = nil
                })

                dataTask.resume()

                self.dataRequest[url] = dataTask
            }}.eraseToAnyPublisher()
    }

    public func cancelRequest(of url: URL) {
        self.queue.sync { [weak self] in
            self?.dataRequest[url]?.cancel()
            self?.dataRequest[url] = nil
        }
    }

    @available(iOS 15.0.0, *)
    func downloadData(from url: URL) async throws -> Data {
        let request = URLRequest.init(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

        return data
    }
}
