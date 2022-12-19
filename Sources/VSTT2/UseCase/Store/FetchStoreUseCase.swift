//
//  FetchStoreUseCase.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

class FetchStoreUseCase {
  let repository: IStoreRepository

  init(repository: IStoreRepository) {
    self.repository = repository
  }

  func invoke(clientId: Int64, completion: @escaping (Error?) -> Void) {
    repository.getStores(clientId: clientId) { (result) in
      switch result {
      case .success(let stores):
        self.repository.setCachedStores(stores: stores)
        completion(nil)
      case .failure(let error): completion(error)
      }
    }
  }
}
