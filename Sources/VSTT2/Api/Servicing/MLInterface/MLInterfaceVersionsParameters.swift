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
}

extension MLInterfaceVersionsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .ml }
  var method: RequestType { .GET }
  var path: String { "/getSdkAssetsMlInterfaceVersions" }
}
