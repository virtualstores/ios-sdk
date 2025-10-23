//
//  MLApi.swift
//
//
//  Created by Théodore Roos on 2024-05-30.
//

import Foundation
import Combine
import VSFoundation

protocol IMLApi {
  func fetchMLInterfaceVersions() -> AnyPublisher<MLInterfaceVersions, Error>
  func fetchModel(url: URL) -> AnyPublisher<Data, Error>
}

class MLApi {
  private let tag = "MLApi"
  private let downloadManager = DownloadManager()
  private let mlInterfaceVersionService = MLInterfaceVersionsService(with: NetworkManager())
}

extension MLApi: IMLApi {
  func fetchMLInterfaceVersions() -> AnyPublisher<MLInterfaceVersions, Error> {
    mlInterfaceVersionService.call(with: .init())
  }

  func fetchModel(url: URL) -> AnyPublisher<Data, Error> {
    downloadManager.loadData(from: url)
  }
}
