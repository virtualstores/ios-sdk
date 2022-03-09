//
// UploadScanEventsParameters
// VSTT2
//
// Created by Hripsime on 2022-01-19.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import CoreGraphics

public struct UploadScanEventsParameters {
    private let config: EnvironmentConfig?
    private let apiKey: String
    private let visitId: Int64
    private let requestId: String
    private let barcode: String
    private let shelfId: Int64
    private let point: CGPoint
    private let timeStamp: String
    private let type: ScanType

    enum ScanType: String {
        case shelf = "SHELF"
        case unknown = "UNKOWN"
    }

    init(apiKey: String, visitId: Int64, requestId: String, barcode: String, shelfId: Int64,
         point: CGPoint, timeStamp: String, type: ScanType, config: EnvironmentConfig?) {
        self.apiKey = apiKey
        self.visitId = visitId
        self.requestId = requestId
        self.barcode = barcode
        self.shelfId = shelfId
        self.point = point
        self.timeStamp = timeStamp
        self.type = type
        self.config = config
    }
}

extension UploadScanEventsParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var path: String { "/scanevents" }

    var queryItems: [String: String]? {
        let parameters = ["visitId": String(visitId), "requestId": requestId] as [String: String]

        return parameters
    }

    var parameters: [String: Any]? {
        let parameters = ["barcode": barcode,
                          "shelfIf": shelfId,
                          "x": Double(point.x),
                          "y": Double(point.y),
                          "timestamp": timeStamp,
                          "type": type.rawValue] as [String: Any]

        return parameters
    }

    var headers: [String: String]? { ["apiKey": apiKey ] }
}
