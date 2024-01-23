//
//  SetActiveStoreUseCase.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

class SetActiveStoreUseCase {
  let repository: IStoreRepository

  init(repository: IStoreRepository) {
    self.repository = repository
  }

  func invoke(storeId: Int64) {
    guard let store = repository.getCachedStores().first(where: { $0.id == storeId }) else { fatalError("Could not find active stores") }
    repository.setActiveStore(store: store)
  }
}
