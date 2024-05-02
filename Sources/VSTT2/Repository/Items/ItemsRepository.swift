//
//  File.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

protocol IItemsRepository {
  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ())
  func getCachedItems(by barcode: String) -> Item?
  func addCachedItem(item: Item)
  func reset()
}

class ItemsRepository {
  let api: IItemsApi = ItemsApi()

  var cachedItems: [String:Item] = [:]

  private var serialDispatch = DispatchQueue(label: "TT2ItemsRepository")
}

extension ItemsRepository: IItemsRepository {
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
