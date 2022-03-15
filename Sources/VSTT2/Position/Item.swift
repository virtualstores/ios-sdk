//
// Item
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation

public class Item {
    public var name: String
    public var externalId: String
    public var itemPositions: [ItemPosition]
    public var itemPosition: ItemPosition? { itemPositions.first }
    
    public init(name: String, externalId: String, itemPositions: [ItemPosition]) {
        self.name = name
        self.externalId = externalId
        self.itemPositions = itemPositions
    }
}
