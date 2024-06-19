//
//  UploadDevicePostionParameters.swift
//
//
//  Created by Théodore Roos on 2024-06-18.
//

import Foundation
import VSFoundation

struct UploadDevicePostionParameters {
  @Inject var config: EnvironmentConfig
  let userId: String
  let storeId: Int64
  let rtlsOptionsId: Int64
  let signal: VPSOutputSignal.Position
}

extension UploadDevicePostionParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .central }
  var method: RequestType { .PUT }
  var path: String { "/devices/positions" }
  var parameters: Any? {
    [
      "id": userId,
      "storeId": storeId,
      "rtlsOptionsId": rtlsOptionsId,
      "x": signal.position.x,
      "y": signal.position.y,
      "radiusInMeters": signal.std,
      //"description": "Test",
      //"timestamp": "2024-06-18T10:12:41.159Z",
      //"state": "IDLE",
      //"tags": [:],
      //"lngLat": [
      //  40,
      //  4
      //]
    ]
  }
}
