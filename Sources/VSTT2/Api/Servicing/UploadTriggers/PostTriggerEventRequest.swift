//
// PostTriggerEventRequest
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics

public struct AppTrigger {
    let event: String
}
struct PostTriggerEventRequest {
    let name: String
    let timeStamp: String
    let userPosition: CGPoint
    let appTrigger: AppTrigger?
    let tags: Tags?
    let metaData: MetaData?

    struct Tags {
        let userId: String
        let elapsedTimeInMinutes: String
    }

    struct MetaData {
        let title: String
        let description: String
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
