//
// ShelfDto
// VSTT2
//
// Created by Hripsime on 2022-01-23
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics

public struct ShelfDto: Codable {
    public var shelfId: Int64?
    public var shelfGroupId: Int64?
    public var name: String?
    public var itemPositionX: Double?
    public var itemPositionY: Double?
    public var itemPositionOffsetX: Double?
    public var itemPositionOffsetY: Double?
    public var points: [PointDto]?
    public var shelfTiers: [ShelfTierDto]?

    public init(shelfId: Int64?, shelfGroupId: Int64?, name: String?, itemPositionX: Double?, itemPositionY: Double?, itemPositionOffsetX: Double?, itemPositionOffsetY: Double?, points: [PointDto]?, shelfTiers: [ShelfTierDto]?) {
        self.shelfId = shelfId
        self.shelfGroupId = shelfGroupId
        self.name = name
        self.itemPositionX = itemPositionX
        self.itemPositionY = itemPositionY
        self.itemPositionOffsetX = itemPositionOffsetX
        self.itemPositionOffsetY = itemPositionOffsetY
        self.points = points
        self.shelfTiers = shelfTiers
    }

    public enum CodingKeys: String, CodingKey {
        case shelfId = "id"
        case shelfGroupId
        case name
        case itemPositionX
        case itemPositionY
        case itemPositionOffsetX
        case itemPositionOffsetY
        case points
        case shelfTiers
    }
}

public extension ShelfDto {
    static func toShelf(_ dto: ShelfDto) -> Shelf {
        let itemPosition = ItemPosition(xPosition: dto.itemPositionX ?? 0.0, yPosition: dto.itemPositionY ?? 0.0,
                                        offsetX: dto.itemPositionOffsetX ?? 0.0, offsetY: dto.itemPositionOffsetY ?? 0.0)

        let points = dto.points ?? []

        let shape = points.map({ (point) -> CGPoint in CGPoint(x: point.x!, y: point.y!) })

        return Shelf(id: dto.shelfId ?? 0,
                     name: dto.name ?? "",
                     itemPosition: itemPosition,
                     shelfGroupPosition: Int(dto.shelfGroupId ?? 0),
                     shelfTiers: dto.shelfTiers?.map(ShelfTierDto.toShelfTier) ?? [],
                     shape: shape)
    }
}
