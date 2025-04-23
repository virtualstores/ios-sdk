//
//  UploadGeoPositionsParameters.swift
//
//
//  Created by Théodore Roos on 2023-12-12.
//

import Foundation
import VSFoundation

struct UploadGeoPositionsParameters {
  @Inject var config: EnvironmentConfig
  let visitId: Int64
  let requestId: String
  let positions: [String: [RecordedPositionLngLat]]

  init(visitId: Int64, requestId: String, positions: [String : [RecordedPositionLngLat]]) {
    self.visitId = visitId
    self.requestId = requestId
    self.positions = positions
  }

  enum TypeEnum: String {
    case gps = "gps"
    case fullGPS = "full-gps"
    case vpsMl = "tt2"
    case fullVPSMl = "full-tt2"
    case vpsMlProcessed = "tt2-processed"
  }
}

extension UploadGeoPositionsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .analytics }
  var method: RequestType { .POST }
  var path: String { "/geopositions" }
  var queryItems: [String: String]? {
    ["requestId": requestId, "visitId": String(visitId)]
  }
  var parameters: Any? { positions.asDictionary() }
}

class PersistGeoPositionsParameters: IPersistenceModel {
  var retainOriginalIndex: Bool = false
  var index: String?

  convenience init(index: String) {
    self.init()
    self.index = index
  }

  var visitId: Int64?
  var requestId: String?
  var positions: [String: [RecordedPositionLngLat]]?
}

extension PersistGeoPositionsParameters {
  var asParams: UploadGeoPositionsParameters? {
    guard
      let visitId = visitId,
      let requestId = requestId,
      let positions = positions
    else { return nil }
    return UploadGeoPositionsParameters(
      visitId: visitId,
      requestId: requestId,
      positions: positions
    )
  }
}
