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
    private let scanEvent: ScanEvent

    init(visitId: Int64, requestId: String, scanEvent: ScanEvent) {
        self.visitId = visitId
        self.requestId = requestId
        self.scanEvent = scanEvent
    }
}

extension UploadScanEventsParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType { .analytics }
    var method: RequestType { .POST }
    var path: String { "/scanevents" }
    var queryItems: [String: String]? { ["visitId": String(visitId), "requestId": requestId] }
    var parameters: Any? { [ scanEvent.asParameters ] }
}

private extension ScanEvent {
  var asParameters: [String:Any] {
    switch type {
    case .shelf:
      return [
        "barcode": barcode,
        "shelfId": shelfId as Any,
        "shelfTierId": shelfTierId as Any,
        "shelfTierPosition": shelfTierPosition as Any,
        "x": point?.x as Any,
        "y": point?.y as Any,
        "timestamp": timestamp,
        "type": "SHELF",
        "userPosition": [
          "type": "METER",
          "coordinate": userPosition?.asArray as Any
        ]
      ]
    case .shelfSection:
      return [
        "barcode": barcode,
        "shelfSectionId": shelfSectionId as Any,
        "rtlsOptionsId": floorLevelId as Any,
        "sectionPosition": sectionPosition as Any,
        "shelfPositionFromLeftToRight": shelfPositionFromLeftToRight as Any,
        "x": point?.x as Any,
        "y": point?.y as Any,
        "timestamp": timestamp,
        "type": "SHELF_SECTION",
        "userPosition": [
          "type": "METER",
          "coordinate": userPosition?.asArray as Any
        ]
      ]
    case .zone:
      return [
        "barcode": barcode,
        "rtlsOptionsId": floorLevelId as Any,
        "timestamp": timestamp,
        "type": "ZONE",
        "userPosition": [
          "type": "METER",
          "coordinate": userPosition?.asArray as Any
        ],
        "zoneIds": zoneIds as Any
      ]
    case .unknown:
      return [
        "barcode": barcode,
        "rtlsOptionsId": floorLevelId as Any,
        "x": point?.x as Any,
        "y": point?.y as Any,
        "timestamp": timestamp,
        "type": "UNKNOWN",
        "userPosition": [
          "type": "METER",
          "coordinate": userPosition?.asArray as Any
        ]
      ]
    }
  }
}
