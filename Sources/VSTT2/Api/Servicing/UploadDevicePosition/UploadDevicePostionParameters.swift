//
//  UploadDevicePostionParameters.swift
//
//
//  Created by Théodore Roos on 2024-06-18.
//

import CoreLocation
import Foundation
import VSFoundation

struct UploadDevicePostionParameters {
  @Inject var config: EnvironmentConfig
  let userId: String
  let storeId: Int64
  let rtlsOptionsId: Int64
  let signal: VPSOutputSignal.Position
  let coordinate: CLLocationCoordinate2D?
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
      "timestamp": DateFormatter.standardFormatter.string(from: signal.timestamp),
      "state": "ACTIVE",
      //"tags": [:],
      "lngLat": coordinate != nil ? [
        coordinate!.longitude,
        coordinate!.latitude
      ] : nil
    ]
  }
}
