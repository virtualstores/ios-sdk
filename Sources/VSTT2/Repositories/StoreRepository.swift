//
//  StoreRepository.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import VSFoundation

protocol IStoreRepository {
  var activeStore: Store { get }
  var zonesTree: TT2ZonesTree { get }

  func fetchStores(clientId: Int64, completion: @escaping (Error?) -> ())
  func fetchSwapLocations(completion: @escaping (Error?) -> ())
  func getCachedStores() -> [Store]
  func getCachedSwapLocations() -> [SwapLocation]
  func set(activeStore store: Store)
  func set(cachedStores stores: [Store])
}

class StoreRepository {
  let api: IStoreApi = StoreApi()

  private var _activeStore: Store?
  private var cachedStores: [Store] = []
  private var cachedSwapLocations: [SwapLocation] = []
  private var _zonesTree: TT2ZonesTree?
}

extension StoreRepository: IStoreRepository {
  var activeStore: Store {
    guard let store = _activeStore else { fatalError("Store not initialized") }
    return store
  }

  var zonesTree: TT2ZonesTree {
    guard let tree = _zonesTree else { fatalError("Tree not initialized") }
    return tree
  }

  func fetchStores(clientId: Int64, completion: @escaping (Error?) -> ()) {
    api.fetchStores(clientId: clientId) { [weak self] (result) in
      switch result {
      case .success(let stores):
        self?.cachedStores = stores
        completion(nil)
      case .failure(let error): completion(error)
      }
    }
  }

  func fetchSwapLocations(completion: @escaping (Error?) -> ()) {
    api.fetchSwapLocations(storeId: activeStore.id) { [weak self] (result) in
      switch result {
      case .success(let swapLocations):
        self?.cachedSwapLocations = swapLocations
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }

  func getCachedStores() -> [Store] {
    cachedStores
  }

  func getCachedSwapLocations() -> [SwapLocation] {
    cachedSwapLocations
  }

  func set(activeStore store: Store) {
    _activeStore = store
    _zonesTree = .init()
  }

  func set(cachedStores stores: [Store]) {
    cachedStores = stores
  }
}
