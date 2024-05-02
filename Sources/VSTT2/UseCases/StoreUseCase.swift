//
//  StoreUseCase.swift
//
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import VSFoundation

class FetchStoreUseCase {
  @Inject var repository: IStoreRepository

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

class GetActiveStoreUseCase {
  @Inject var repository: IStoreRepository

  func invoke() -> Store {
    repository.activeStore
  }
}

class GetCachedStoreUseCase {
  @Inject var repository: IStoreRepository

  func invoke(filterOnlyActive: Bool = true) -> [Store] {
    filterOnlyActive ? repository.getCachedStores().filter({ $0.active }) : repository.getCachedStores()
  }
}

class SetActiveStoreUseCase {
  @Inject var repository: IStoreRepository

  func invoke(storeId: Int64) {
    guard let store = repository.getCachedStores().first(where: { $0.id == storeId }) else { fatalError("Could not find store") }
    repository.setActiveStore(store: store)
  }
}
