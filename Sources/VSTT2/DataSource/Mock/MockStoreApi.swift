//
//  StoreApi.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import VSFoundation

class MockStoreApi {}

extension MockStoreApi: IStoreApi {
  func fetchStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void) {
    completion(.success([.mockStore]))
  }

  func fetchSwapLocations(storeId: Int64, completion: @escaping (Result<[SwapLocation], Error>) -> ()) {
    completion(.success([]))
  }
}
