//
//  ClientsApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import Combine
import VSFoundation

protocol IClientsApi {
  func get() -> AnyPublisher<[Client], Error>
}

class ClientsApi {
  private let service = ClientsListService(with: NetworkManager())
}

extension ClientsApi: IClientsApi {
  func get() -> AnyPublisher<[Client], Error> {
    service
      .call(with: .init())
      .map { $0.clients }
      .eraseToAnyPublisher()
  }
}
