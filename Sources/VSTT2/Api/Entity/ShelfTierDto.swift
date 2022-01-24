//
// ShelfTierDto
// VSTT2
//
// Created by Hripsime on 2022-01-23
// Copyright Virtual Stores - 2022

import Foundation

public struct ShelfTierDto: Codable {
    public var tierId: Int64?
    public var shelfId: Int64?
    public var shelfPosition: Int?

    public init(tierId: Int64?, shelfId: Int64?, shelfPosition: Int?) {
        self.tierId = tierId
        self.shelfId = shelfId
        self.shelfPosition = shelfPosition
    }

    public enum CodingKeys: String, CodingKey {
        case tierId = "id"
        case shelfId
        case shelfPosition
    }
}

public extension ShelfTierDto {
    static func toShelfTier(_ dto: ShelfTierDto) -> ShelfTier {
        return ShelfTier(id: dto.tierId ?? 0,
                         shelfId: dto.shelfId ?? 0,
                         shelfPosition: dto.shelfPosition ?? 0)
    }
}
