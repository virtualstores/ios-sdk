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
  private let stop: String
  private let positionGrps: [String: [RecordedPosition]]

  init(config: EnvironmentConfig?, requestId: String, visitId: Int64, stop: String, positionGrps: [String: [RecordedPosition]]) {
    self.config = config
    self.requestId = requestId
    self.visitId = visitId
    self.stop = stop
    self.positionGrps = positionGrps
  }
}

extension StopVisitParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var queryItems: [String : String]? {
    let parameters: [String : String] = [
      "requestId": requestId,
      "visitId": String(visitId),
      "timestamp": stop
    ]

    return parameters
  }

  var method: RequestType { .PUT }

  var path: String { "/visits/stop" }

  var parameters: [String : Any]? {
    let parameters: [String : Any] = [ "positionGrps": positionGrps.asDictionary() ]
    return parameters
  }
}
