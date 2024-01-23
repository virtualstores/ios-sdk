//
//  ItemsApi.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import Combine
import VSFoundation

class ItemsApi: IItemsApi {
  let service = ItemPositionService(with: NetworkManager())
  let config: EnvironmentConfig

  init(config: EnvironmentConfig) {
    self.config = config
  }

  private var cancellable = Set<AnyCancellable>()

  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ()) {
    service
      .call(with: ItemPositionParameters(config: config, storeId: storeId, barcode: barcode))
      .sink { (subscriberCompletion) in
        switch subscriberCompletion {
        case .finished: break
        case .failure(let error):
          completion(.failure(error))
        }
      } receiveValue: { (data) in
        completion(.success(data))
      }.store(in: &cancellable)
  }
}
