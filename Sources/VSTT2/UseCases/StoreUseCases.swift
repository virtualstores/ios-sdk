//
//  StoreUseCases.swift
//
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import VSFoundation

class FetchStoreUseCase {
  @Inject var repository: IStoreRepository

  func invoke(clientId: Int64, completion: @escaping (Error?) -> Void) {
    repository.fetchStores(clientId: clientId, completion: completion)
  }
}

class FetchSwapLocationsUseCase {
  @Inject var repository: IStoreRepository

  func invoke(completion: @escaping (Error?) -> ()) {
    repository.fetchSwapLocations(completion: completion)
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

class GetCachedSwapLocationsUseCase {
  @Inject var repository: IStoreRepository

  func invoke() -> [SwapLocation] {
    repository.getCachedSwapLocations()
  }
}

class GetZonesTreeUseCase {
  @Inject var repository: IStoreRepository

  func invoke() -> TT2ZonesTree {
    repository.zonesTree
  }
}

class SetActiveStoreUseCase {
  @Inject var floorRepository: IFloorRepository
  @Inject var storeRepository: IStoreRepository

  func invoke(storeId: Int64) {
    guard let store = storeRepository.getCachedStores().first(where: { $0.id == storeId }) else { fatalError("Could not find store") }
    storeRepository.set(activeStore: store)
    floorRepository.set(cachedFloors: store.rtlsOptions)
  }
}
