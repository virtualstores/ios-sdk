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
  @Inject var statusRepository: IStatusRepository

  func invoke(barcode: String, completion: @escaping (Result<Item, Error>) -> Void) {
    guard let id = try? storeRepository.activeStore.id else { return }
    itemsRepository.getBy(storeId: id, barcode: barcode) { [weak self] (result) in
      switch result {
      case .success(let data):
        self?.itemsRepository.addCachedItem(identfier: barcode, positons: data)
        let itemPositions = data.map { $0.toItemPosition }.compactMap { $0 }
        var closestItemPosition = itemPositions.first
        if let userPosition = self?.statusRepository.currentPosition {
          closestItemPosition = itemPositions.getNearest(to: userPosition.point)
        }

        let item = Item(name: "", externalId: barcode, itemPositions: itemPositions, itemPosition: closestItemPosition)
        DispatchQueue.main.async { completion(.success(item)) }
      case .failure(let error): DispatchQueue.main.async { completion(.failure(error)) }
      }
    }
  }
}

private  extension BarcodePosition {
  var toItemPosition: ItemPosition? {
    guard let point = itemPosition, let offset = itemPositionOffset else { return nil }
    return ItemPosition(point: point, offset: offset, floorLevelId: rtlsOptionsId, shelfId: shelfId, shelfTierId: shelfTierId, shelfTierPosition: shelfTierPosition, identifier: barcode, isDisabled: isDisabled)
  }
}

private extension Array where Element == ItemPosition {
  func getNearest(to position: CGPoint) -> ItemPosition? {
    var closestDistance: Double = .greatestFiniteMagnitude
    var closestPosition: ItemPosition?

    forEach { (itemPosition) in
      let distance = itemPosition.point.distance(to: position)
      if distance < closestDistance {
        closestDistance = distance
        closestPosition = itemPosition
      }
    }
    return closestPosition
  }
}
