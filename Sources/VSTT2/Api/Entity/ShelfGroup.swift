//
// ShelfGroup
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation

public struct ShelfGroup {
    public let id: Int64
    public let name: String
    public let itemPosition: ItemPosition
    public let shelves: [Shelf]

    public init(id: Int64, name: String, itemPosition: ItemPosition, shelves: [Shelf]) {
        self.id = id
        self.name = name
        self.itemPosition = itemPosition
        self.shelves = shelves
    }
}
