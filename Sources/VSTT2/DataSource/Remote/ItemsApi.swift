//
//  ItemsApi.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Combine
import Foundation
import VSFoundation

protocol IItemsApi {
  func getBy(storeId: Int64, barcode: String) -> AnyPublisher<[BarcodePosition], Error>
}

class ItemsApi {
  private let service = ItemPositionService(with: NetworkManager())
}

extension ItemsApi: IItemsApi {
  func getBy(storeId: Int64, barcode: String) -> AnyPublisher<[BarcodePosition], Error> {
    service.call(with: .init(storeId: storeId, barcode: barcode))
  }
}
