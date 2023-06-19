//
//  GetUserParameters.swift
//  
//
//  Created by Théodore Roos on 2022-09-12.
//

import Foundation
import VSFoundation

struct GetUserParameters {
  @Inject var config: EnvironmentConfig
  let clientId: Int64
  let userid: String
}

extension GetUserParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .analytics }
  var method: RequestType { .GET }
  var path: String { "/users/ml" }
  var queryItems: [String : String]? {
    [
      "userid" : userid,
      "clientId" : String(clientId),
      "hardwareType" : "IOS",
      "modifierCount" : String(100)
    ]
  }
}
