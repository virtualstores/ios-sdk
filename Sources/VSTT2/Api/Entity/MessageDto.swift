//
// MessageDto
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics

internal struct MessageCardDto: Codable {
    internal enum CardType: Int, Codable {
        case small = 0
        case big = 1

        func toCartType() -> Message.CardType {
            switch self {
            case .big: return .big
            case .small: return .small
            }
        }
    }

    let title: String
    let description: String?
    let imageUrl: String?
    let type: CardType
}

internal struct ExposureDefinitionDto: Codable {
    internal enum ExposureDefinitionType: Int, Codable {
        case wholeMap = 0
        case zones = 1
        case products = 2
        case category = 3
        case welcome = 4

        func toExposureType() -> Message.ExposureType {
            switch self {
            case .wholeMap: return .wholeMap
            case .zones: return .zones
            case .products: return .products
            case .category: return .category
            case .welcome: return .welcome
            }
        }
    }

    let type: ExposureDefinitionType
    let productRadiusInMeters: Double?
    let zones: [ExposureZoneDto]?
    let selectedProducts: [ExposureProductsDto]?
    let clientCategories: [ExposureCategoryDto]?
}

internal struct ExposureZoneDto: Codable {
    let id: String
    let rtlsOptionsId: Int
    let coordinates: [[[Double]]]
}

internal struct ExposureProductsDto: Codable {
    let storeId: Int64?
    let barcode: String
}

internal struct ExposureCategoryDto: Codable {
    let id: Int64
    let clientId: Int64
    let name: String
}

internal struct MessageDto: Codable {
    let id: Int64
    let name: String
    let from: String
    let to: String
    let card: MessageCardDto
    let exposureDefinition: ExposureDefinitionDto

    func toMessage() -> Message? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            .withDashSeparatorInDate,
            .withFullDate,
            .withColonSeparatorInTime
        ]

        // TODO: Variable modifiedToDate is temporary. Which makes it possible to include the last date of the incoming period from the server
        guard let fromDate = dateFormatter.date(from: from), let toDate = dateFormatter.date(from: to),
              let modifiedToDate = Calendar.current.date(byAdding: .day, value: 1, to: toDate) else {
            return nil
        }

        return Message(
            id: self.id,
            name: self.name,
            duration: DateInterval(start: fromDate, end: modifiedToDate),
            cardType: self.card.type.toCartType(),
            title: self.card.title,
            description: self.card.description ?? "",
            image: URL(string: self.card.imageUrl ?? ""),
            exposureType: self.exposureDefinition.type.toExposureType(),
            radius: self.exposureDefinition.productRadiusInMeters ?? 10.0,
            zones: self.exposureDefinition.zones?.map { MapZone(id: $0.rtlsOptionsId, name: $0.id, zone: $0.coordinates[0].map { CGPoint(x: $0[0], y: $0[1]) })} ?? [],
            selectedProducts: self.exposureDefinition.selectedProducts?.map { Message.Product(storeId: $0.storeId, barcode: $0.barcode) },
            categories: self.exposureDefinition.clientCategories?.map { Message.Category(id: $0.id, clientId: $0.clientId, name: $0.name) },
            shelf: nil
        )
    }
}
