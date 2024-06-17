//
//  PositionUseCases.swift
//
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import VSFoundation

class GetPositionByBarcodeUseCase {
  @Inject var itemsRepository: IItemsRepository
  @Inject var storeRepository: IStoreRepository

  func invoke(barcode: String, completion: @escaping (Result<Item, Error>) -> Void) {
    if let item = itemsRepository.getCachedItems(by: barcode) {
      completion(.success(item))
    } else {
      itemsRepository.getBy(storeId: storeRepository.activeStore.id, barcode: barcode) { (result) in
        switch result {
        case .success(let data):
          let item = PositionBusiness().handleSuccessResult(barcode: barcode, data: data)
          self.itemsRepository.addCachedItem(item: item)
          DispatchQueue.main.async { completion(.success(item)) }
        case .failure(let error): DispatchQueue.main.async { completion(.failure(error)) }
        }
      }
    }
  }
}

class PositionBusiness {
  func handleSuccessResult(barcode: String, data: [BarcodePosition]) -> Item {
    let itemPositions = data.map { $0.toItemPosition }.compactMap { $0 }
    return Item(name: "", externalId: barcode, itemPositions: itemPositions)
  }
}

extension BarcodePosition {
  var toItemPosition: ItemPosition? {
    guard let point = itemPosition, let offset = itemPositionOffset else { return nil }
    return ItemPosition(point: point, offset: offset, floorLevelId: rtlsOptionsId, shelfId: shelfId, shelfTierId: shelfTierId, shelfTierPosition: shelfTierPosition, identifier: barcode, isDisabled: isDisabled)
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
