//
//  SetActiveStoreUseCase.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

class SetActiveStoreUseCase {
  let repo: IStoreRepository

  init(repo: IStoreRepository) {
    self.repo = repo
  }

  func invoke(storeId: Int64) {
    guard let store = repo.getCachedStores().first(where: { $0.id == storeId }) else { fatalError("Could not find active stores") }
    repo.setActiveStore(store: store)
  }
}
