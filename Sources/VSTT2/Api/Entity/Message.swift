//
// Message
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import UIKit
import VSFoundation

public struct Message: Equatable, Hashable {
    public struct Product {
        public let storeId: Int64?
        public let barcode: String

        public init(storeId: Int64?, barcode: String) {
            self.storeId = storeId
            self.barcode = barcode
        }
    }

    public struct Category {
        public let id: Int64
        public let clientId: Int64
        public let name: String

        public init(id: Int64, clientId: Int64, name: String) {
            self.id = id
            self.clientId = clientId
            self.name = name
        }
    }

    public enum CardType {
        case small
        case big
    }

    public enum ExposureType {
        case wholeMap
        case zones
        case products
        case category
        case welcome
    }

    public let id: Int64
    public let name: String
    public let duration: DateInterval

    public let cardType: CardType
    public let title: String
    public let description: String
    public let image: URL?
    public let exposureType: ExposureType
    // Zones is defined in degrees
    public let radius: Double
    public let zones: [MapZone]
    public let selectedProducts: [Product]?
    public let categories: [Category]?
    public let shelf: Shelf?

    public var asPointOfInterest: PointOfInterest {
        PointOfInterest(id: String(id), alternateIds: [], name: title, subtitle: description, description: "", position: shelf?.itemPosition, addedByUser: false, imageUrl: image, type: PointOfInterest.message)
    }

    public init(id: Int64, name: String, duration: DateInterval, cardType: CardType, title: String, description: String, image: URL?, exposureType: ExposureType, radius: Double, zones: [MapZone], selectedProducts: [Product]?, categories: [Category]?, shelf: Shelf?) {
        self.id = id
        self.name = name
        self.duration = duration
        self.cardType = cardType
        self.title = title
        self.description = description
        self.image = image
        self.exposureType = exposureType
        self.radius = radius
        self.zones = zones
        self.selectedProducts = selectedProducts
        self.categories = categories
        self.shelf = shelf
    }

    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension Message: AreaEvent {
    public var area: EventArea {
        let path = UIBezierPath()
        self.zones.forEach { zone in
            guard let firstCoordinate = zone.zone.first else { return }

            let zoneCurve = UIBezierPath()
            zoneCurve.move(to: firstCoordinate)

            zone.zone[1...].forEach { point in
                zoneCurve.addLine(to: point)
            }

            path.append(zoneCurve)
        }
        return path
    }
}
