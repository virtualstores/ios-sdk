//
// PointOfInterest
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2022

import Foundation

public struct PointOfInterest: Hashable, Equatable, Codable {
    public static let message = "message"

    public struct Quantity: Codable {
        public var amount: Double
        public let unit: UnitOfMeasure
    }

    public let id: String
    public let alternateIds: [String]
    public var name: String
    public var subtitle: String
    public var description: String
    public var quantity: Quantity?
    public var position: ItemPosition?
    public var addedByUser: Bool
    public var imageUrl: URL?
    public var type: String
    public var pathfindable: Bool = true
    public internal(set) var timestamp: Date?

    init(id: String, alternateIds: [String], name: String, subtitle: String, description: String,
         quantity: Quantity? = nil, position: ItemPosition? = nil, addedByUser: Bool,
         imageUrl: URL?, type: String, pathfindable: Bool = true, timestamp: Date? = nil) {
        self.id = id
        self.alternateIds = alternateIds
        self.name = name
        self.subtitle = subtitle
        self.description = description
        self.quantity = quantity
        self.position = position
        self.addedByUser = addedByUser
        self.imageUrl = imageUrl
        self.type = type
        self.pathfindable = pathfindable
        self.timestamp = timestamp
    }

    public static func == (lhs: PointOfInterest, rhs: PointOfInterest) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
