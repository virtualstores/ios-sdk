//
// UploadScanEventsParameters
// VSTT2
//
// Created by Hripsime on 2022-01-19.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import CoreGraphics

public enum ScanEventType: String {
    case shelf = "SHELF"
    case shelfSection = "SHELF_SECTION"
}

struct UploadScanEventsParameters {
    @Inject var config: EnvironmentConfig
    private let visitId: Int64
    private let requestId: String
    private let position: ItemPosition
    private let timestamp: String
    private let scanType: ScanEventType

    init(visitId: Int64, requestId: String, position: ItemPosition, timestamp: String, type: ScanEventType) {
        self.visitId = visitId
        self.requestId = requestId
        self.position = position
        self.timestamp = timestamp
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
        [ scanType.asParameters(position: position, timestamp: timestamp) ]
    }
}

extension ScanEventType {
  func asParameters(position: ItemPosition, timestamp: String) -> [String:Any] {
    switch self {
    case .shelf:
      return [
        "barcode": position.identifier,
        "shelfId": position.shelfId as Any,
        "shelfTierId": position.shelfTierId as Any,
        "shelfTierPosition": position.shelfTierPosition as Any,
        "x": Double(position.point.x),
        "y": Double(position.point.y),
        "timestamp": timestamp,
        "type": self.rawValue
      ]
    //case .shelfSection:
    //  return [
    //    "barcode": position.identifier,
    //    "shelfSectionId": String(),
    //    "rtlsOptionsId": Int64(),
    //    "sectionPosition": Int64(),
    //    "shelfPositionFromLeftToRight": Int64(),
    //    "x": Double(position.point.x),
    //    "y": Double(position.point.y),
    //    "timestamp": timestamp,
    //    "type": self.rawValue
    //  ]
    default: fatalError("Case not handled, please use .shelf")
    }
  }
}
