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

  func invoke(storeId: Int64, completion: @escaping (Error?) -> ()) {
    repository.fetchSwapLocations(storeId: storeId, completion: completion)
  }
}

class GetActiveStoreUseCase {
  @Inject var repository: IStoreRepository

  func invoke() throws -> Store {
    try repository.activeStore
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

  func invoke() throws -> TT2ZonesTree {
    try repository.zonesTree
  }
}

class SetActiveStoreUseCase {
  @Inject var floorRepository: IFloorRepository
  @Inject var storeRepository: IStoreRepository

  func invoke(storeId: Int64) throws {
    guard let store = storeRepository.getCachedStores().first(where: { $0.id == storeId }) else { throw TT2Error.missingData }
    storeRepository.set(activeStore: store)
    floorRepository.set(cachedFloors: store.rtlsOptions)
  }
}

class ValidateVisitScoreUseCase {
  @Inject var repository: IStoreRepository

  func invoke(score: Int, timestamp: Date) -> VisitScore? {
    guard let threshold = try? repository.activeStore.acceptedScoreLimit else { return nil }
    return .init(score: score, isAccepted: score>=threshold, timestamp: timestamp)
  }
}
