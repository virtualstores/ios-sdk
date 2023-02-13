//
// Item
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

public class Item {
    public var name: String
    public var externalId: String
    public var itemPositions: [ItemPosition]
    public var uniquePositions: [ItemPosition] { unique() }
    public var itemPosition: ItemPosition? { checkForMaxAllowedDistinctItemPositions() ? itemPositions.first : nil }
    
    public init(name: String, externalId: String, itemPositions: [ItemPosition]) {
        self.name = name
        self.externalId = externalId
        self.itemPositions = itemPositions
    }

    private func checkForMaxAllowedDistinctItemPositions(max: Int = 1) -> Bool {
        unique().count == max
    }

    private func unique() -> [ItemPosition] {
        var uniquePositions: [ItemPosition] = []
        itemPositions.map { $0.shelfId }.compactMap { $0 }.uniqued().forEach { (shelfId) in
            guard let position = itemPositions.first(where: { $0.shelfId == shelfId }) else { return }
            uniquePositions.append(position)
        }
        return uniquePositions
    }
}
