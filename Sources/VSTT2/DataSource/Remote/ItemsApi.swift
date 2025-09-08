//
//  ItemsApi.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import Combine
import VSFoundation

protocol IItemsApi: Disposable {
  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ())
}

class ItemsApi {
  private let tag = "ItemsApi"
  private let service = ItemPositionService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension ItemsApi: IItemsApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellable.removeAll()
  }
  
  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ()) {
    service
      .call(with: ItemPositionParameters(storeId: storeId, barcode: barcode))
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
