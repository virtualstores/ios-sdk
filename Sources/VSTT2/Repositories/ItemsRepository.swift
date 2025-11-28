//
//  ItemsRepository.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Combine
import Foundation
import VSFoundation

protocol IItemsRepository {
  func getBy(storeId: Int64, barcode: String) -> AnyPublisher<[BarcodePosition], Error>
  func getCachedItems(by identfier: String) -> [BarcodePosition]?
  func addCachedItem(identfier: String, positons: [BarcodePosition])
  func reset()
}

class ItemsRepository {
  private let tag = "ItemsRepository"
  private let api: IItemsApi = ItemsApi()
  private var cachedItems: [String:[BarcodePosition]] = [:]
  private var serialDispatch = DispatchQueue(label: "TT2ItemsRepository")

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
  }
}

extension ItemsRepository: IItemsRepository {
  func getBy(storeId: Int64, barcode: String) -> AnyPublisher<[BarcodePosition], Error> {
    Deferred { [weak self] () -> AnyPublisher<[BarcodePosition], Error> in
      guard let self = self else { return .fail(with: TT2Error.missingData) }
      guard let cached = getCachedItems(by: barcode) else {
        return api.getBy(storeId: storeId, barcode: barcode)
      }
      return Just(cached).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    .receive(on: serialDispatch)
    .eraseToAnyPublisher()
  }

  func getCachedItems(by identfier: String) -> [BarcodePosition]? {
    serialDispatch.sync {
      cachedItems[identfier]
    }
  }

  func addCachedItem(identfier: String, positons: [BarcodePosition]) {
    serialDispatch.sync { cachedItems[identfier] = positons }
  }

  func reset() {
    serialDispatch.sync { cachedItems.removeAll() }
  }
}
