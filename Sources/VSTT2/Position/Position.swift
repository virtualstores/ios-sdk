//
// Position
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import VSFoundation

public class Position: IPosition {
    @Inject var itemPositionService: ItemPositionService

    private var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    private var shelfGroups: [ShelfGroup]?
    private var config: EnvironmentConfig?
    private var store: Store?
    private var barcodePositions: [Item] = []
    private var cancellable = Set<AnyCancellable>()
    
    public init() {}
    
    func setup(with shelfGroups: [ShelfGroup], config: EnvironmentConfig, store: Store) {
        self.shelfGroups = shelfGroups
        for group in shelfGroups {
            for shelf in group.shelves {
                for tier in shelf.shelfTiers {
                    self.shelfTierItemPositions[tier.id] = shelf.itemPosition
                }
            }
        }

        self.config = config
        self.store = store
    }
    
    public func getBy(shelfName: String, completion: @escaping (ItemPosition) -> ()) {
        var position: ItemPosition?
        shelfGroups?.forEach { shelfGroup in
            if let shelf = shelfGroup.shelves.first(where: { $0.name == shelfName }) {
                position = shelf.itemPosition
            }
        }
        
        guard let itemPosition = position else { return }
        
        completion(itemPosition)
    }

    public func getBy(barcode: String, completion: @escaping (Item?) -> ()) {
        guard let store = store else { return }

        if let item = barcodePositions.first(where: { $0.externalId == barcode }) {
            completion(item)
        } else {
            itemPositionService
                .call(with: ItemPositionParameters(storeId: store.id, barcode: barcode, config: config))
                .sink { (subscriberCompletion) in
                    switch subscriberCompletion {
                    case .finished: break
                    case .failure(let error):
                        Logger(verbosity: .debug).log(message: error.localizedDescription)
                        completion(nil)
                    }
                } receiveValue: { [weak self] (data) in
                  var itemPositions: [ItemPosition] = []
                  data.forEach { (position) in
                    guard let point = position.itemPosition, let offset = position.itemPositionOffset, let floorLevelId = store.rtlsOptions.first(where: { $0.id == (position.rtlsOptionsId ?? -1) })?.id else { return }
                    itemPositions.append(ItemPosition(point: point, offset: offset, floorLevelId: floorLevelId))
                  }
                  let item = Item(name: "", externalId: barcode, itemPositions: itemPositions)
                  self?.barcodePositions.append(item)
                  completion(item)
                }.store(in: &cancellable)
        }
    }

    public func getBy(barcodes: [String], completion: @escaping ([Item]) -> ()) {
        let group = DispatchGroup()
        var positions: [Item] = []

        group.enter()
        barcodes.forEach { (barcode) in
            self.getBy(barcode: barcode) { data in
                if let data = data {
                    positions.append(data)
                }
                if let last = barcodes.last, barcode == last {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(positions)
        }
    }
}
