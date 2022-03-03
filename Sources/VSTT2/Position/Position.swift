//
// Position
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import Combine

public class Position: IPosition {
    var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    
    public init() {}
    
    func setup(with shelfGroups: [ShelfGroup]) {
        for group in shelfGroups {
            for shelf in group.shelves {
                for tier in shelf.shelfTiers {
                    self.shelfTierItemPositions[tier.id] = shelf.itemPosition
                }
            }
        }
    }
    
    public func getByShelfName(shelfName: String, completion: @escaping (ItemPosition) -> ()) {
        //check if name is id
        guard let id = Int64(shelfName), let position = shelfTierItemPositions[id] else { return }
        
        completion(position)
    }

    public func getByBarcode(barcode: String, completion: @escaping (Item) -> ()) {

    }

    public func getByBarcode(barcodes: [String], completion: @escaping ([Item]) -> ()) {

    }
}
