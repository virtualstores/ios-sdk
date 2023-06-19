//
// UploadScanEventsParameters
// VSTT2
//
// Created by Hripsime on 2022-01-19.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import CoreGraphics

struct UploadScanEventsParameters {
    @Inject var config: EnvironmentConfig
    private let visitId: Int64
    private let requestId: String
    private let barcode: String
    private let shelfId: Int64
    private let point: CGPoint
    private let timeStamp: String
    private let scanType: ScanType

    enum ScanType: String {
        case shelf = "SHELF"
        case unknown = "UNKNOWN"
    }

    init(visitId: Int64, requestId: String, barcode: String, shelfId: Int64,
         point: CGPoint, timeStamp: String, type: ScanType) {
        self.visitId = visitId
        self.requestId = requestId
        self.barcode = barcode
        self.shelfId = shelfId
        self.point = point
        self.timeStamp = timeStamp
        self.scanType = type
    }
}

extension UploadScanEventsParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType { .analytics }
    var method: RequestType { .POST }
    var path: String { "/scanevents" }
    var queryItems: [String: String]? {
        ["visitId": String(visitId), "requestId": requestId]
    }

    var parameters: Any? {
        [
            [
                "barcode": barcode,
                "shelfId": shelfId,
                "x": Double(point.x),
                "y": Double(point.y),
                "timestamp": timeStamp,
                "type": scanType.rawValue
            ]
        ]
    }
}
