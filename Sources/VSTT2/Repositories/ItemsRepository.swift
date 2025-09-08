//
//  ItemsRepository.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import VSFoundation

protocol IItemsRepository: Disposable {
  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ())
  func getCachedItems(by barcode: String) -> Item?
  func addCachedItem(item: Item)
  func reset()
}

class ItemsRepository {
  private let tag = "ItemsRepository"
  private let api: IItemsApi = ItemsApi()
  private var cachedItems: [String:Item] = [:]
  private var serialDispatch = DispatchQueue(label: "TT2ItemsRepository")

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }
}

extension ItemsRepository: IItemsRepository {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    api.dispose()
  }
  
  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ()) {
    api.getBy(storeId: storeId, barcode: barcode, completion: completion)
  }

  func getCachedItems(by barcode: String) -> Item? {
    serialDispatch.sync {
      cachedItems[barcode]
    }
  }

  func addCachedItem(item: Item) {
    serialDispatch.sync { cachedItems[item.externalId] = item }
  }

  func reset() {
    serialDispatch.sync { cachedItems.removeAll() }
  }
}
