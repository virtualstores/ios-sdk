//
//  MLInterfaceVersionsParameters.swift
//  
//
//  Created by Théodore Roos on 2023-04-11.
//

import Foundation

struct MLInterfaceVersionsParameters {
  private let config: EnvironmentConfig = EnvironmentConfig()

  init() {
    config.centralServerConnection = ServerConnection(apiKey: "kanelbulle", serverAddress: "https://lmz7vrr223.execute-api.eu-north-1.amazonaws.com")
  }
}

extension MLInterfaceVersionsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .central }
  var method: RequestType { .GET }
  var path: String { "/getSdkAssetsMlInterfaceVersions" }
}
