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
    @Inject var config: EnvironmentConfig

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

    init(visitId: Int64, requestId: String, barcode: String, shelfId: Int64,
         point: CGPoint, timeStamp: String, type: ScanType) {
        self.visitId = visitId
        self.requestId = requestId
        self.barcode = barcode
        self.shelfId = shelfId
        self.point = point
        self.timeStamp = timeStamp
        self.type = type
    }
}

extension UploadScanEventsParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    // Analytics base URL seems different, check if it will be the same after
    var baseURL: String { "https://gunnis-hp-stat.ih.vs-office.se/api/scanevents?visitiId=\(visitId)&requestId=\(requestId)" }

 //   var path: String { "/v2/positions?visitId=\(visitId)&requestId=\(requestId)" }

    var parameters: [String: Any]? {
        let parameters = ["barocde": barcode,
                          "shelfIf": shelfId,
                          "x": Double(point.x),
                          "y": Double(point.y),
                          "timestamp": timeStamp,
                          "type": type.rawValue] as [String: Any]

        return parameters
    }

    var headers: [String: String]? { ["apiKey" : "8fc1be06-582e-41ce-b309-61e8fa8e3784" ] }
}

