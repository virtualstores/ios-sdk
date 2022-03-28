//
// ShelfGroupDto
// VSTT2
//
// Created by Hripsime on 2022-01-23
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

public struct ShelfGroupDto: Codable {
    public var shelfGroupId: Int64?
    public var name: String?
    public var itemPositionX: Double?
    public var itemPositionY: Double?
    public var itemPositionOffsetX: Double?
    public var itemPositionOffsetY: Double?
    public var points: [PointDto]?
    public var shelves: [ShelfDto]?
    public var floorLevelId: Int64?

    public init(shelfGroupId: Int64?, name: String?, itemPositionX: Double?, itemPositionY: Double?, itemPositionOffsetX: Double?, itemPositionOffsetY: Double?, points: [PointDto]?, shelves: [ShelfDto]?) {
        self.shelfGroupId = shelfGroupId
        self.name = name
        self.itemPositionX = itemPositionX
        self.itemPositionY = itemPositionY
        self.itemPositionOffsetX = itemPositionOffsetX
        self.itemPositionOffsetY = itemPositionOffsetY
        self.points = points
        self.shelves = shelves
    }

    public enum CodingKeys: String, CodingKey {
        case shelfGroupId = "id"
        case name
        case itemPositionX
        case itemPositionY
        case itemPositionOffsetX
        case itemPositionOffsetY
        case points
        case shelves
    }
}

public extension ShelfGroupDto {
    static func add(floorLevelId: Int64, _ dtos: [ShelfGroupDto]) -> [ShelfGroupDto] {
        var modifiedShelfGroupDtos: [ShelfGroupDto] = []
        dtos.forEach { shelfGroup in
          var modifiedShelfGroup = shelfGroup
          modifiedShelfGroup.floorLevelId = floorLevelId

          var modifiedShelves: [ShelfDto] = []
          shelfGroup.shelves?.forEach({ shelf in
            var modifiedShelf = shelf
            modifiedShelf.floorLevelId = floorLevelId
            modifiedShelves.append(modifiedShelf)
          })
          modifiedShelfGroup.shelves = modifiedShelves
          
          modifiedShelfGroupDtos.append(modifiedShelfGroup)
        }

        return modifiedShelfGroupDtos
    }

    static func toShelfGroups(_ dtos: [ShelfGroupDto]) -> [ShelfGroup] {
        return dtos.map(ShelfGroupDto.toShelfGroup)
    }

    static func toShelfGroup(_ dto: ShelfGroupDto) -> ShelfGroup {
        let itemPosition =  ItemPosition(
            xPosition: dto.itemPositionX ?? 0.0, yPosition: dto.itemPositionY ?? 0.0,
            offsetX: dto.itemPositionOffsetX ?? 0.0, offsetY: dto.itemPositionOffsetY ?? 0.0,
            floorLevelId: dto.floorLevelId ?? -1)

        return ShelfGroup(id: dto.shelfGroupId ?? 0,
                          name: dto.name ?? "",
                          itemPosition: itemPosition,
                          shelves: dto.shelves?.map(ShelfDto.toShelf) ?? [])
    }
}
