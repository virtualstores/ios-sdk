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
  func fetchStores(clientId: Int64) -> AnyPublisher<[Store], Error>
  func fetchSwapLocations(storeId: Int64) -> AnyPublisher<[SwapLocation], Error>
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
  
  func fetchStores(clientId: Int64) -> AnyPublisher<[Store], Error> {
    storesService
      .call(with: .init(clientId: clientId))
      .ensure({ !$0.stores.isEmpty }, elseThrow: TT2Error.noAvailableStores)
      .map { $0.stores }
      .eraseToAnyPublisher()
  }

  func fetchSwapLocations(storeId: Int64) -> AnyPublisher<[SwapLocation], Error> {
    swapLocationsService.call(with: .init(storeId: storeId))
  }
}
