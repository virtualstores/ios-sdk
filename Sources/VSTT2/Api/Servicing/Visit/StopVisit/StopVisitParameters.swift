//
//  StopVisitParameters.swift
//  
//
//  Created by Théodore Roos on 2022-03-26.
//

import Foundation

public struct StopVisitParameters {
  private let config: EnvironmentConfig?
  private let requestId: String
  private let visitId: Int64
  private let stopTimestamp: String

  init(config: EnvironmentConfig?, requestId: String, visitId: Int64, stopTimestamp: String) {
    self.config = config
    self.requestId = requestId
    self.visitId = visitId
    self.stopTimestamp = stopTimestamp
  }
}

extension StopVisitParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var queryItems: [String : String]? {
    let parameters: [String : String] = [
      "requestId": requestId,
      "visitId": String(visitId),
      "timestamp": stopTimestamp
    ]

    return parameters
  }

  var method: RequestType { .PUT }

  var path: String { "/visits/stop" }
}
