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

class StoreApi {
  let service = StoresListService(with: NetworkManager())
  var cancellable = Set<AnyCancellable>()
}

extension StoreApi: IStoreApi {
  func getStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void) {
    service
      .call(with: StoresListParameters(clientId: clientId))
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
