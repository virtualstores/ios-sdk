//
//  ClientsApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import Combine
import VSFoundation

class MockClientsApi {
  let service = ClientsListService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension MockClientsApi: IClientsApi {
  func get(completion: @escaping (Result<[Client], Error>) -> Void) {
    completion(.success([.init(clientId: 1, name: "Mock Client", dataServerUrl: nil, dataServerApiKey: nil)]))
  }
}
