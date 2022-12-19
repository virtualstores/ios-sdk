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
    @Inject var getPositionByBarcodeUseCase: GetPositionByBarcodeUseCase

    private var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    public internal(set) var shelfGroups: [ShelfGroup]?
    private var config: EnvironmentConfig?
    var store: Store?
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
        getPositionByBarcodeUseCase.itemsRepository.reset()
    }
    
    public func getBy(shelfName: String, completion: @escaping (ItemPosition?) -> ()) {
        var position: ItemPosition?
        shelfGroups?.forEach { shelfGroup in
            if let shelf = shelfGroup.shelves.first(where: { $0.name == shelfName }) {
                position = shelf.itemPosition
            }
        }
        
        DispatchQueue.main.async { completion(position) }
    }

    public func getBy(barcode: String, completion: @escaping (Item?) -> ()) {
        getPositionByBarcodeUseCase.invoke(barcode: barcode) { (item) in
            DispatchQueue.main.async { completion(item) }
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
            DispatchQueue.main.async { completion(positions) }
        }
    }
    
    deinit {
        cancellable.removeAll()
    }
}
