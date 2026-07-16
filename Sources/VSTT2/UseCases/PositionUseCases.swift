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
  @Inject var floorRepository: IFloorRepository

  func invoke(barcode: String, itemSettings: ItemSettings, completion: @escaping (Result<Item, Error>) -> Void) {
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

        let zonePosition = closestItemPosition?.getZonePosition(
          for: (try? self?.floorRepository.activeZoneShelves) ?? [],
          zones: (try? self?.storeRepository.zonesTree.getZonesForCurrentFloorLevel()) ?? [],
          zoneLookupScope: itemSettings.zoneLookupScope,
        )?.asZonePosition(barcode: barcode)

        DispatchQueue.main.async { completion(.success(
          Item(
            name: itemSettings.obfuscateBarcode ? "_" : barcode,
            externalId: itemSettings.obfuscateBarcode ? "_" : barcode,
            itemPositions: itemPositions,
            itemPosition: zonePosition == nil ? closestItemPosition : nil,
            zonePosition: zonePosition
          )
        ))}
      case .failure(let error): DispatchQueue.main.async { completion(.failure(error)) }
      }
    }
  }
}

private extension BarcodePosition {
  var toItemPosition: ItemPosition? {
    guard let point = itemPosition, let offset = itemPositionOffset else { return nil }
    return ItemPosition(point: point, offset: offset, floorLevelId: rtlsOptionsId, shelfId: shelfId, shelfTierId: shelfTierId, shelfTierPosition: shelfTierPosition, identifier: barcode, isDisabled: isDisabled)
  }
}

private extension ItemPosition {
  func getZonePosition(for zoneShelves: [Shelf], zones: [Zone], zoneLookupScope: ItemSettings.ZoneLookupScope) -> Zone? {
    guard zoneShelves.first(where: { $0.id == shelfId }) != nil else { return nil }
    let zones: [Zone] = zones.filter({ $0.properties.zoneType != "EXPOSURE_POINT" })

    let childMatch = zoneLookupScope != .parentOnly ? zones.filter { $0.parent != nil }.findContaining(point) : nil

    guard zoneLookupScope != .childOnly else { return childMatch }

    return childMatch ?? zones.filter { $0.parent == nil }.findContaining(point)
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

private extension Array where Element == Zone {
  func findContaining(_ point: CGPoint) -> Zone? {
    first(where: { $0.contains(point: point) })
  }
}
