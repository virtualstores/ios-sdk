//
// IPosition
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import VSFoundation

public protocol IPosition {
  /// Method will return ItemPosition for shelfName
  func getBy(shelfName: String, completion: @escaping (Result<ItemPosition, Error>) -> ())

  /// Method will return Item for barcode
  func getBy(barcode: String, itemSettings: ItemSettings, completion: @escaping (Result<Item, Error>) -> ())

  /// Method will return Items for barcodes
  func getBy(barcodes: [String], itemSettings: ItemSettings, completion: @escaping (Result<[Item], Error>) -> ())
}

public extension IPosition {
  func getBy(barcode: String, itemSettings: ItemSettings = .init(), completion: @escaping (Result<Item, Error>) -> ()) {
    getBy(barcode: barcode, itemSettings: itemSettings, completion: completion)
  }

  func getBy(barcodes: [String], itemSettings: ItemSettings = .init(), completion: @escaping (Result<[Item], Error>) -> ()) {
    getBy(barcodes: barcodes, itemSettings: itemSettings, completion: completion)
  }
}
