//
//  ClientsUseCases.swift
//
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import VSFoundation

class FetchClientsUseCase {
  @Inject var repository: IClientRepository

  func invoke(completion: @escaping (Result<[Client], Error>) -> ()) {
    repository.fetch { (result) in
      switch result {
      case .success(let clients):
        self.repository.set(cachedClients: clients)
        completion(.success(clients))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

class GetActiveClientUseCase {
  @Inject var repository: IClientRepository

  func invoke() throws -> Client {
    try repository.client
  }
}

class GetCachedClientsUseCase {
  @Inject var repository: IClientRepository

  func invoke() -> [Client] {
    repository.get()
  }
}

class SetActiveClientUseCase {
  @Inject var repository: IClientRepository

  func invoke(clientId: Int64) throws {
    guard let client = repository.get().first(where: { $0.clientId == clientId }) else { throw TT2Error.missingData }
    repository.set(activeClient: client)
  }
}
