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
    dispose()
  }
}

extension ItemsRepository: IItemsRepository {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    api.dispose()
  }
  
  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ()) {
    if let cached = getCachedItems(by: barcode) {
      completion(.success(cached))
    } else {
      api.getBy(storeId: storeId, barcode: barcode, completion: completion)
    }
  }

  private func getRemoteBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ()) {
    getBy(storeId: storeId, barcode: barcode, completion: completion)
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
