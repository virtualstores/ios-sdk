//
//  ClientsApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import Combine

protocol IClientsApi {
  func get(completion: @escaping (Result<[Client], Error>) -> Void)
}

class ClientsApi {
  let service = ClientsListService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension ClientsApi: IClientsApi {
  func get(completion: @escaping (Result<[Client], Error>) -> Void) {
    service
      .call(with: ClientsListParameters())
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      } receiveValue: { (data) in
        completion(.success(data.clients))
      }.store(in: &cancellable)
  }
}
