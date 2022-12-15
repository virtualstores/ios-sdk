//
//  FetchStoreUseCase.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

class FetchStoreUseCase {
  let repo: IStoreRepository

  init(repo: IStoreRepository) {
    self.repo = repo
  }

  func invoke(clientId: Int64, completion: @escaping (Error?) -> Void) {
    repo.getStores(clientId: clientId) { (result) in
      switch result {
      case .success(let stores):
        self.repo.setCachedStores(stores: stores)
        completion(nil)
      case .failure(let error): completion(error)
      }
    }
  }
}
