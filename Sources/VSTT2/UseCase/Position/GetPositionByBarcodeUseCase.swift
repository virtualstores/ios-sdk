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

  func invoke(storeId: Int64, barcode: String, completion: @escaping (Item?) -> Void) {
    let business = PositionBusiness(storeRepository: storeRepository, itemsRepository: itemsRepository)
    if let item = business.getCachedItem(barcode: barcode) {
      completion(item)
    } else {
      business.getItem(barcode: barcode, completion: completion)
    }
  }
}

class PositionBusiness {
  let storeRepository: IStoreRepository
  let itemsRepository: IItemsRepository

  init(storeRepository: IStoreRepository, itemsRepository: IItemsRepository) {
    self.storeRepository = storeRepository
    self.itemsRepository = itemsRepository
  }

  func getItem(barcode: String, completion: @escaping (Item?) -> Void) {
    itemsRepository.getBy(storeId: storeRepository.activeStore.id, barcode: barcode) { (result) in
      switch result {
      case .success(let data):
        var itemPositions: [ItemPosition] = []
        data.forEach { (position) in
          guard let point = position.itemPosition, let offset = position.itemPositionOffset else { return }
          itemPositions.append(ItemPosition(point: point, offset: offset, floorLevelId: position.rtlsOptionsId, shelfId: position.shelfId, identifier: position.barcode))
        }
        let item = Item(name: "", externalId: barcode, itemPositions: itemPositions)
        self.itemsRepository.addCachedItem(item: item)
        completion(item)
      case .failure(_): completion(nil)
      }
    }
  }

  func getCachedItem(barcode: String) -> Item? {
    itemsRepository.getCachedItems(by: barcode)
  }
}
