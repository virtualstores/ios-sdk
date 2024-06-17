//
//  MLApi.swift
//
//
//  Created by Théodore Roos on 2024-05-30.
//

import Foundation
import Combine

protocol IMLApi {
  func fetchMLInterfaceVersions(completion: @escaping (Result<MLInterfaceVersions, Error>) -> ())
  func fetchModel(url: URL, completion: @escaping (Result<Data, Error>) -> ())
}

class MLApi {
  let downloadManager = DownloadManager()
  let mlInterfaceVersionService = MLInterfaceVersionsService(with: NetworkManager())
  var cancellable = Set<AnyCancellable>()
}

extension MLApi: IMLApi {
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
