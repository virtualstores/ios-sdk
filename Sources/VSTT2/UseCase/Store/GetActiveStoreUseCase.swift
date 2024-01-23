//
//  GetActiveStoreUseCase.swift
//  
//
//  Created by Théodore Roos on 2022-12-19.
//

import Foundation

class GetActiveStoreUseCase {
  let repository: IStoreRepository

  init(repository: IStoreRepository) {
    self.repository = repository
  }

  func invoke() -> Store {
    repository.activeStore
  }
}
