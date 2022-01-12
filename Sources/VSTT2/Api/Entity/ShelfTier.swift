//
// ShelfTier
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation

public struct ShelfTier: Codable {
    public let id: Int64
    public let shelfId: Int64
    public let shelfPosition: Int

    public init(id: Int64, shelfId: Int64, shelfPosition: Int) {
        self.id = id
        self.shelfId = shelfId
        self.shelfPosition = shelfPosition
    }
}
