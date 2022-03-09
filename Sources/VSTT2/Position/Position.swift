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
    private var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    private var shelfGroups: [ShelfGroup]?
    
    public init() {}
    
    func setup(with shelfGroups: [ShelfGroup]) {
        self.shelfGroups = shelfGroups
        for group in shelfGroups {
            for shelf in group.shelves {
                for tier in shelf.shelfTiers {
                    self.shelfTierItemPositions[tier.id] = shelf.itemPosition
                }
            }
        }
    }
    
    public func getByShelfName(shelfName: String, completion: @escaping (ItemPosition) -> ()) {
        var position: ItemPosition?
        shelfGroups?.forEach({ shelfGroup in
            if let shelf = shelfGroup.shelves.first(where: { $0.name == shelfName }) {
                position = shelf.itemPosition
            }
        })
        
        guard let itemPosition = position else { return }
        
        completion(itemPosition)
    }

    public func getByBarcode(barcode: String, completion: @escaping (Item) -> ()) {

    }

    public func getByBarcode(barcodes: [String], completion: @escaping ([Item]) -> ()) {

    }
}
