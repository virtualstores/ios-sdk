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
  private let vpsProfile: VPSProfileDto?
  private let config: EnvironmentConfig?

  init(clientId: Int64, userId: String, vpsProfile: VPSProfileDto?, config: EnvironmentConfig?) {
    self.clientId = clientId
    self.userId = userId
    self.vpsProfile = vpsProfile
    self.config = config
  }
}

extension PutUserParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var path: String { "/users/tags" }

  var method: RequestType { .PUT }

  var queryItems: [String : String]? {
    return [
      "userId" : userId,
      "clientId" : String(clientId)
    ]
  }

  var parameters: [String : Any]? {
//    return [
//      "id" : user.id,
//      "userId" : user.userId,
//      "height" : user.height,
//      "name" : user.name,
//      "age" : user.age,
//      "gender" : user.gender,
//      "route" : user.route,
//      "comments" : user.comments,
//      "activity" : user.activity,
//      "deviceName" : user.deviceName
//    ]
    vpsProfile?.asDictionary()
  }
}
