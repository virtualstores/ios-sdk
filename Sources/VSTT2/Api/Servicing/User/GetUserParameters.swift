//
//  GetUserParameters.swift
//  
//
//  Created by Théodore Roos on 2022-09-12.
//

import Foundation

struct GetUserParameters {
  private let clientId: Int64
  private let userid: String
  private let config: EnvironmentConfig?

  init(clientId: Int64, userid: String, config: EnvironmentConfig?) {
    self.clientId = clientId
    self.userid = userid
    self.config = config
  }
}

extension GetUserParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var path: String { "/users/ml" }

  var method: RequestType { .GET }

  var queryItems: [String : String]? {
    [
      "userid" : userid,
      "clientId" : String(clientId),
      "hardwareType" : "IOS",
      "modifierCount" : String(100)
    ]
  }
}
