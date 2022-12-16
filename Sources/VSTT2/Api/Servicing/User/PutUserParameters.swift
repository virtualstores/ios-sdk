//
//  PutUserParameters.swift
//  
//
//  Created by Théodore Roos on 2022-09-12.
//

import Foundation
import VSFoundation

struct PutUserParameters {
  private let clientId: Int64
  private let userId: String
  private let mlData: [PersonalMLDataDTO]
  private let config: EnvironmentConfig?
  private let requestId = UUID().uuidString.uppercased()

  init(clientId: Int64, userId: String, mlData: [PersonalMLDataDTO], config: EnvironmentConfig?) {
    self.clientId = clientId
    self.userId = userId
    self.mlData = mlData
    self.config = config
  }
}

extension PutUserParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var path: String { "/users/ml" }

  var method: RequestType { .PUT }

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
