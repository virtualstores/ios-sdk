//
//  File.swift
//  
//
//  Created by Théodore Roos on 2022-09-13.
//

import Foundation
import VSFoundation

struct DeleteUserParameters {
  private let clientId: Int64
  private let userId: String
  private let config: EnvironmentConfig?
  private let requestId = UUID().uuidString

  init(clientId: Int64, userId: String, config: EnvironmentConfig?) {
    self.clientId = clientId
    self.userId = userId
    self.config = config
  }
}

extension DeleteUserParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var path: String { "/users" }

  var method: RequestType { .DELETE }

  var queryItems: [String : String]? {
    return [
      "userId" : userId,
      "clientId" : String(clientId),
      "hardwareType" : "IOS",
      "requestId" : requestId
    ]
  }
}
