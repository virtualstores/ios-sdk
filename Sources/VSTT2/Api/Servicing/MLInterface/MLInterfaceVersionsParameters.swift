//
//  MLInterfaceVersionsParameters.swift
//  
//
//  Created by Théodore Roos on 2023-04-11.
//

import Foundation

public struct MLInterfaceVersionsParameters {
  private let config: EnvironmentConfig

  init() {
    let config = EnvironmentConfig()
    config.centralServerConnection = ServerConnection(apiKey: "kanelbulle", serverAddress: "https://lmz7vrr223.execute-api.eu-north-1.amazonaws.com", mqttAddress: nil, storeId: nil)
    self.config = config
  }
}

extension MLInterfaceVersionsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var method: RequestType { .GET }

  var path: String { "/getSdkAssetsMlInterfaceVersions" }
}
