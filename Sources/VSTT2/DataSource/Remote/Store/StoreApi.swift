//
//  StoreApi.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import Combine
import VSFoundation

protocol IStoreApi {
  func getStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void)
}

class StoreApi: IStoreApi {
  let config: EnvironmentConfig

  let service = StoresListService(with: NetworkManager())

  var cancellable = Set<AnyCancellable>()

  init(config: EnvironmentConfig) {
    self.config = config
  }

  func getStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void) {
    let parameters = StoresListParameters(config: config, clientId: clientId)

    service
      .call(with: parameters)
      .sink(receiveCompletion: { (result) in
        switch result {
        case .finished:
          break
        case .failure(let error):
          completion(.failure(error))
          Logger(verbosity: .critical).log(message: "No available store")
        }
      }, receiveValue: { (data) in
        completion(.success(data.stores))
      }).store(in: &cancellable)
  }
}
