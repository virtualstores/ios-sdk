//
// PostTriggerEventRequest
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics

struct PostTriggerEventRequest: Codable {
    let rtlsOptionsId: String
    let name: String
    let timestamp: String
    let userPosition: CGPoint
    let appTrigger: AppTrigger?
    let coordinateTrigger: CoordinateTrigger?
    let shelfTrigger: ShelfTrigger?
    let zoneTrigger: ZoneTrigger?
    let tags: [String: String]
    let metaData: [String: String]
    
    struct AppTrigger: Codable {
        let event: String
    }

    struct CoordinateTrigger: Codable {
        let point: CGPoint
        let radius: Double
    }

    struct ShelfTrigger: Codable {
        let shelfGroupId: Int?
        let shelfId: Int?
        let shelfTierId: Int?
    }

    struct ZoneTrigger: Codable {
        let zoneId: String
        let groupId: String
        let type: ZoneType

        enum ZoneType: String, Codable {
            case enter = "ENTER"
            case exit = "EXIT"
        }
    }
}

struct PostScanEventsRequest {
    let barcode: String
    let shelfId: Int64
    let point: CGPoint
    let timeStamp: String
    let type: ScanType

    enum ScanType: String {
        case shelf = "SHELF"
        case unknown = "UNKOWN"
    }
}
