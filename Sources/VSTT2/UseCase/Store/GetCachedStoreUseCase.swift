//
//  GetCachedStoreUseCase.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

class GetCachedStoreUseCase {
  let repository: IStoreRepository

  init(repository: IStoreRepository) {
    self.repository = repository
  }

  func invoke(filterOnlyActive: Bool = true) -> [Store] {
    filterOnlyActive ? repository.getCachedStores().filter({ $0.active }) : repository.getCachedStores()
  }
}
