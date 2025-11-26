//
//  ClientRepository.swift
//
//
//  Created by Théodore Roos on 2024-05-02.
//

import Combine
import Foundation
import VSFoundation

protocol IClientRepository: Disposable {
  var client: Client { get throws }

  func get() -> [Client]
  func set(activeClient: Client)
  func set(cachedClients: [Client])
  func fetch() -> AnyPublisher<[Client], Error>
}

class ClientRepository {
  private let tag = "ClientRepository"
  private let api: IClientsApi = ClientsApi()
  private var _activeClient: Client?
  private var clients: [Client] = []

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }
}

extension ClientRepository: IClientRepository {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    _activeClient = nil
    clients = []
  }
  
  var client: Client {
    get throws {
      guard let client = _activeClient else { throw TT2Error.noClientSet }
      return client
    }
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

  func fetch() -> AnyPublisher<[Client], Error> {
    api.get()
  }
}
