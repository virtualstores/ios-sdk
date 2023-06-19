//
//  StopVisitParameters.swift
//  
//
//  Created by Théodore Roos on 2022-03-26.
//

import Foundation
import VSFoundation

struct StopVisitParameters {
  @Inject var config: EnvironmentConfig
  let requestId: String
  let visitId: Int64
  let stopTimestamp: String
}

extension StopVisitParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .analytics }
  var method: RequestType { .PUT }
  var path: String { "/visits/stop" }
  var queryItems: [String : String]? {
    [
      "requestId": requestId,
      "visitId": String(visitId),
      "timestamp": stopTimestamp
    ]
  }
}
