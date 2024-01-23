//
//  File.swift
//  
//
//  Created by Théodore Roos on 2022-09-13.
//

import Foundation
import VSFoundation

struct DeleteUserParameters {
  @Inject var config: EnvironmentConfig
  let clientId: Int64
  let userId: String
  let requestId = UUID().uuidString.uppercased()
}

extension DeleteUserParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .analytics }
  var method: RequestType { .DELETE }
  var path: String { "/users" }
  var queryItems: [String : String]? {
    [
      "userId" : userId,
      "clientId" : String(clientId),
      "hardwareType" : "IOS",
      "requestId" : requestId
    ]
  }
}
