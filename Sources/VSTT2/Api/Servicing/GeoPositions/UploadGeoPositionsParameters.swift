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
    case vpsMl = "vps-ml"
    case vpsMlProcessed = "vps-ml-processed"
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
