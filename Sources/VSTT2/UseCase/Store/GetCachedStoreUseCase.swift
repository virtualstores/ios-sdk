//
//  GetCachedStoreUseCase.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

import Foundation

class GetCachedStoreUseCase {
  let repo: IStoreRepository

  init(repo: IStoreRepository) {
    self.repo = repo
  }

  func invoke(filterOnlyActive: Bool = true) -> [Store] {
    filterOnlyActive ? repo.getCachedStores().filter({ $0.active }) : repo.getCachedStores()
  }
}
