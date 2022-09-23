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
  private let vpsProfile: VPSProfileDto?
  private let config: EnvironmentConfig?

  init(clientId: Int64, userId: String, vpsProfile: VPSProfileDto?, config: EnvironmentConfig?) {
    self.clientId = clientId
    self.userId = userId
    self.vpsProfile = vpsProfile
    self.config = config
  }
}

extension DeleteUserParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var path: String { "/users/tags" }

  var method: RequestType { .DELETE }

  var queryItems: [String : String]? {
    return [
      "userId" : userId,
      "clientId" : String(clientId)
    ]
  }

  var parametersDictionary: [String : Any]? {
    vpsProfile?.asDictionary()
  }
}
