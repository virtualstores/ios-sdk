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

class ItemsRepository: IItemsRepository {
  let api: IItemsApi

  var cachedItems: [String:Item] = [:]

  init(api: IItemsApi) {
    self.api = api
  }

  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ()) {
    api.getBy(storeId: storeId, barcode: barcode, completion: completion)
  }

  func getCachedItems(by barcode: String) -> Item? {
    cachedItems[barcode]
  }

  func addCachedItem(item: Item) {
    cachedItems[item.externalId] = item
  }

  func reset() {
    cachedItems.removeAll()
  }
}
