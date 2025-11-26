//
//  StoreRepository.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Combine
import Foundation
import VSFoundation

protocol IStoreRepository: Disposable {
  var activeStore: Store { get throws }
  var zonesTree: TT2ZonesTree { get throws }

  func fetchStores(clientId: Int64) -> AnyPublisher<Void, Error>
  func fetchSwapLocations(storeId: Int64) -> AnyPublisher<Void, Error>
  func getCachedStores() -> [Store]
  func getCachedSwapLocations() -> [SwapLocation]
  func set(activeStore store: Store)
  func set(cachedStores stores: [Store])
}

class StoreRepository {
  let api: IStoreApi = StoreApi()

  private let tag = "StoreRepository"
  private var _activeStore: Store?
  private var cachedStores: [Store] = []
  private var cachedSwapLocations: [SwapLocation] = []
  private var _zonesTree: TT2ZonesTree?

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }
}

extension StoreRepository: IStoreRepository {
  var activeStore: Store {
    get throws {
      guard let store = _activeStore else { throw TT2Error.noStoreSet }
      return store
    }
  }

  var zonesTree: TT2ZonesTree {
    get throws {
      guard let tree = _zonesTree else { throw TT2Error.missingData }
      return tree
    }
  }

  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    _activeStore = nil
    cachedStores = []
    cachedSwapLocations = []
    _zonesTree?.dispose()
    _zonesTree = nil
  }

  func fetchStores(clientId: Int64) -> AnyPublisher<Void, Error> {
    api.fetchStores(clientId: clientId)
      .handleEvents(receiveOutput: { [weak self] in
        self?.cachedStores = $0
      })
      .map { _ in () }
      .eraseToAnyPublisher()
  }

  func fetchSwapLocations(storeId: Int64) -> AnyPublisher<Void, Error> {
    api.fetchSwapLocations(storeId: storeId)
      .handleEvents(receiveOutput: { [weak self] in
        self?.cachedSwapLocations = $0
      })
      .map { _ in ()}
      .eraseToAnyPublisher()
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
