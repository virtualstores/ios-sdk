//
//  StoreApi.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import Combine
import VSFoundation

protocol IStoreApi: Disposable {
  func fetchStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void)
  func fetchSwapLocations(storeId: Int64, completion: @escaping (Result<[SwapLocation], Error>) -> ())
}

class StoreApi {
  private let tag = "StoreApi"
  private let storesService = StoresListService(with: NetworkManager())
  private let swapLocationsService = SwapLocationsService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension StoreApi: IStoreApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellable.removeAll()
  }
  
  func fetchStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void) {
    storesService
      .call(with: StoresListParameters(clientId: clientId))
      .sink(receiveCompletion: { (result) in
        switch result {
        case .finished:
          break
        case .failure(let error):
          completion(.failure(error))
          Logger(verbosity: .critical).log(message: "No available store")
        }
      }, receiveValue: { (data) in
        completion(.success(data.stores))
      }).store(in: &cancellable)
  }

  func fetchSwapLocations(storeId: Int64, completion: @escaping (Result<[SwapLocation], Error>) -> ()) {
    swapLocationsService
      .call(with: SwapLocationsParameters(storeId: storeId))
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      } receiveValue: { (swapLocations) in
        completion(.success(swapLocations))
      }.store(in: &cancellable)
  }
}
