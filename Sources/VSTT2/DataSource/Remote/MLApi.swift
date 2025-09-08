//
//  MLApi.swift
//
//
//  Created by Théodore Roos on 2024-05-30.
//

import Foundation
import Combine
import VSFoundation

protocol IMLApi: Disposable {
  func fetchMLInterfaceVersions(completion: @escaping (Result<MLInterfaceVersions, Error>) -> ())
  func fetchModel(url: URL, completion: @escaping (Result<Data, Error>) -> ())
}

class MLApi {
  private let tag = "MLApi"
  private let downloadManager = DownloadManager()
  private let mlInterfaceVersionService = MLInterfaceVersionsService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension MLApi: IMLApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellable.removeAll()
  }
  
  func fetchMLInterfaceVersions(completion: @escaping (Result<MLInterfaceVersions, Error>) -> ()) {
    mlInterfaceVersionService
      .call(with: MLInterfaceVersionsParameters())
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      } receiveValue: { completion(.success($0)) }
      .store(in: &cancellable)
  }

  func fetchModel(url: URL, completion: @escaping (Result<Data, Error>) -> ()) {
    downloadManager.loadData(from: url, completion: completion)
  }
}
