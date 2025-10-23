//
//  ClientsApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import Combine
import VSFoundation

protocol IClientsApi: Disposable {
  func get(completion: @escaping (Result<[Client], Error>) -> Void)
}

class ClientsApi {
  private let tag = "ClientsApi"
  private let service = ClientsListService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension ClientsApi: IClientsApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellable.removeAll()
  }
  
  func get(completion: @escaping (Result<[Client], Error>) -> Void) {
    service
      .call(with: ClientsListParameters())
      .map { $0.clients }
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellable)
  }
}
