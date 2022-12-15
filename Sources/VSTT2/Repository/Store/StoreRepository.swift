//
//  StoreRepository.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

protocol IStoreRepository {
  var activeStore: Store { get }
  
  func getStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void)
  func getCachedStores() -> [Store]
  func setCachedStores(stores: [Store])
  func setActiveStore(store: Store)
}

class StoreRepository: IStoreRepository {
  let api: IStoreApi

  var cachedStores: [Store] = []
  private var _activeStore: Store?
  var activeStore: Store {
    guard let store = _activeStore else { fatalError("Store not initialized") }
    return store
  }

  init(api: IStoreApi) {
    self.api = api
  }

  func getStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void) {
    api.getStores(clientId: clientId, completion: completion)
  }

  func getCachedStores() -> [Store] {
    cachedStores
  }

  func setCachedStores(stores: [Store]) {
    cachedStores = stores
  }

  func setActiveStore(store: Store) {
    _activeStore = store
  }
}
