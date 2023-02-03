//
//  GetPositionByBarcodeUseCase.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import VSFoundation

class GetPositionByBarcodeUseCase {
  let storeRepository: IStoreRepository
  let itemsRepository: IItemsRepository

  init(storeRepository: IStoreRepository, itemsRepository: IItemsRepository) {
    self.storeRepository = storeRepository
    self.itemsRepository = itemsRepository
  }

  func invoke(barcode: String, completion: @escaping (Item?) -> Void) {
    if let item = itemsRepository.getCachedItems(by: barcode) {
      completion(item)
    } else {
      itemsRepository.getBy(storeId: storeRepository.activeStore.id, barcode: barcode) { (result) in
        switch result {
        case .success(let data):
          let item = PositionBusiness().handleSuccesResult(barcode: barcode, data: data)
          if let item = item {
            self.itemsRepository.addCachedItem(item: item)
          }
          completion(item)
        case .failure(_): completion(nil)
        }
      }
    }
  }
}

class PositionBusiness {
  func handleSuccesResult(barcode: String, data: [BarcodePosition]) -> Item? {
    let itemPositions = data.map { $0.toItemPosition }.compactMap { $0 }
    guard checkForMaxAllowedDistinctItemPositions(positions: itemPositions, max: 1) else { return nil }
    return Item(name: "", externalId: barcode, itemPositions: itemPositions)
  }

  func checkForMaxAllowedDistinctItemPositions(positions: [ItemPosition], max: Int) -> Bool {
    positions.map { $0.shelfId }.compactMap { $0 }.uniqued().count == max
  }
}

extension BarcodePosition {
  var toItemPosition: ItemPosition? {
    guard let point = itemPosition, let offset = itemPositionOffset else { return nil }
    return ItemPosition(point: point, offset: offset, floorLevelId: rtlsOptionsId, shelfId: shelfId, identifier: barcode)
  }
}

extension Array where Element: Hashable {
  func uniqued() -> Array {
    var buffer = Array()
    var added = Set<Element>()
    forEach { (elem) in
      if !added.contains(elem) {
        buffer.append(elem)
        added.insert(elem)
      }
    }
    return buffer
  }
}
