//
//  PutUserParameters.swift
//  
//
//  Created by Théodore Roos on 2022-09-12.
//

import Foundation
import VSFoundation

struct PutUserParameters {
  @Inject var config: EnvironmentConfig
  let requestId = UUID().uuidString.uppercased()
  let clientId: Int64
  let userId: String
  let mlData: [PersonalMLDataDTO]
}

extension PutUserParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .analytics }
  var method: RequestType { .PUT }
  var path: String { "/users/ml" }
  var queryItems: [String : String]? {
    [
      "userId" : userId,
      "clientId" : String(clientId),
      "hardwareType" : "IOS",
      "requestId" : requestId
    ]
  }

  var parameters: Any? {
    var paramters: [[String:Any]] = []
    mlData.forEach { (dto) in
      paramters.append([
        "version" : dto.version,
        "timestamp" : dto.timestamp,
        "mlAlgoTag" : dto.mlAlgoTag.rawValue,
        "deviceOrientation" : dto.deviceOrientation.rawValue,
        "speedModifier" : dto.speedModifier,
        "angleModifier" : dto.angleModifier,
        "driftModifier" : dto.driftModifier,
        "properties" : dto.properties.asDictionary()
      ])
    }
    return paramters
  }
}
