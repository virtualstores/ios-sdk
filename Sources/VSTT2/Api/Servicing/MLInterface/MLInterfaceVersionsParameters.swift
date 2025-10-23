//
//  MLInterfaceVersionsParameters.swift
//  
//
//  Created by Théodore Roos on 2023-04-11.
//

import Foundation
import VSFoundation

struct MLInterfaceVersionsParameters {
  @Inject var config: EnvironmentConfig

  init() {
    if config.connection.tt2MLModelServer == nil {
      config.connection.tt2MLModelServer = .init(
        baseUrl: "https://lmz7vrr223.execute-api.eu-north-1.amazonaws.com",
        authType: .apiKey
      )
    }
  }
}

extension MLInterfaceVersionsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType? { .ml }
  var method: RequestType { .GET }
  var path: String { "/getSdkAssetsMlInterfaceVersions" }
}
