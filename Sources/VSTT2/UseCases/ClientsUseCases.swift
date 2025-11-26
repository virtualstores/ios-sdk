//
//  ClientsUseCases.swift
//
//
//  Created by Théodore Roos on 2024-05-02.
//

import Combine
import Foundation
import VSFoundation

class FetchClientsUseCase {
  @Inject var repository: IClientRepository

  func invoke() -> AnyPublisher<Void, Error> {
    repository.fetch()
      .handleEvents(receiveOutput: { [weak self] in
        self?.repository.set(cachedClients: $0)
      })
      .map { _ in () }
      .eraseToAnyPublisher()
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
