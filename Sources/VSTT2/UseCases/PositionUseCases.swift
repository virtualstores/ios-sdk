//
//  PositionUseCases.swift
//
//
//  Created by Théodore Roos on 2022-12-15.
//

import Combine
import Foundation
import VSFoundation

class GetPositionByBarcodeUseCase {
  @Inject var itemsRepository: IItemsRepository
  @Inject var storeRepository: IStoreRepository
  @Inject var statusRepository: IStatusRepository
  @Inject var floorRepository: IFloorRepository

  func invoke(barcode: String) -> AnyPublisher<Item, Error> {
    return .justOrFail { try storeRepository.activeStore.id }
      .flatMap { [weak self] in
        self?.itemsRepository.getBy(storeId: $0, barcode: barcode) ?? .fail(with: NSError(domain: "GetPositionByBarcodeUseCase", code: -1))
      }
      .handleEvents(receiveOutput: { [weak self] in
        guard $0.contains(where: { $0.toItemPosition != nil }) else { return }
        self?.itemsRepository.addCachedItem(identfier: barcode, positons: $0)
      })
      .map { $0.map { $0.toItemPosition }.compactMap { $0 } }
      .map { [weak self] (itemPositions) -> Item in
        var closestItemPosition = itemPositions.first
        if let userPosition = self?.statusRepository.currentPosition {
          closestItemPosition = itemPositions.getNearest(to: userPosition.point)
        }

        let zonePosition = closestItemPosition?.getZonePosition(
          for: (try? self?.floorRepository.activeZoneShelves) ?? [],
          zones: (try? self?.storeRepository.zonesTree.getZonesForCurrentFloorLevel()) ?? []
        )?.asZonePosition(barcode: barcode)

        return Item(
          name: barcode,
          externalId: barcode,
          itemPositions: itemPositions,
          itemPosition: zonePosition == nil ? closestItemPosition : nil,
          zonePosition: zonePosition
        )
      }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}

private extension BarcodePosition {
  var toItemPosition: ItemPosition? {
    guard let point = itemPosition, let offset = itemPositionOffset else { return nil }
    return ItemPosition(point: point, offset: offset, floorLevelId: rtlsOptionsId, shelfId: shelfId, shelfTierId: shelfTierId, shelfTierPosition: shelfTierPosition, identifier: barcode, isDisabled: isDisabled)
  }
}

private extension ItemPosition {
  func getZonePosition(for zoneShelves: [Shelf], zones: [Zone]) -> Zone? {
    guard let shelf = zoneShelves.first(where: { $0.id == shelfId }) else { return nil }
    return zones
      .filter({ $0.properties.zoneType != "EXPOSURE_POINT" })
      .first(where: { $0.contains(point: shelf.itemPosition.pointWithOffset) })
  }
}

private extension Zone {
  func asZonePosition(barcode: String) -> ZonePosition? {
    guard let point = navigationPoint else { return nil }
    return .init(floorLevelId: floorLevelId, id: id, name: name, names: names, point: point, identifier: barcode)
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
