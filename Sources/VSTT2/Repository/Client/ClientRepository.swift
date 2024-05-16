//
//  ClientRepository.swift
//
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation

protocol IClientRepository {
  var client: Client { get }

  func get() -> [Client]
  func set(activeClient: Client)
  func set(cachedClients: [Client])
  func fetch(completion: @escaping (Result<[Client], Error>) -> ())
}

class ClientRepository {
  let api: IClientsApi = ClientsApi()
  private var _activeClient: Client?
  private var clients: [Client] = []
}

extension ClientRepository: IClientRepository {
  var client: Client {
    guard let client = _activeClient else { fatalError("Client not set") }
    return client
  }

  func get() -> [Client] {
    clients
  }

  func set(activeClient: Client) {
    _activeClient = activeClient
  }

  func set(cachedClients: [Client]) {
    clients = cachedClients
  }

  func fetch(completion: @escaping (Result<[Client], Error>) -> ()) {
    api.get(completion: completion)
  }
}
