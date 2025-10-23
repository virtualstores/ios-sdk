//
//  TriggerEventsParameters.swift
//  
//
//  Created by Théodore Roos on 2022-04-11.
//

import Foundation
import VSFoundation

struct TriggerEventsParameters {
  @Inject var config: EnvironmentConfig
  let storeId: Int64
}

extension TriggerEventsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType? { .central }
  var method: RequestType { .GET }
  var path: String { "/triggerevents/messages" }
  var queryItems: [String:String]? { ["storeId": String(storeId)] }
}
