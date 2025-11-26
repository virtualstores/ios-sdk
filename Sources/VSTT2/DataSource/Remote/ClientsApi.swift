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
  func get() -> AnyPublisher<[Client], Error>
}

class ClientsApi {
  private let tag = "ClientsApi"
  private let service = ClientsListService(with: NetworkManager())
}

extension ClientsApi: IClientsApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
  }
  
  func get() -> AnyPublisher<[Client], Error> {
    service
      .call(with: .init())
      .map { $0.clients }
      .eraseToAnyPublisher()
  }
}
