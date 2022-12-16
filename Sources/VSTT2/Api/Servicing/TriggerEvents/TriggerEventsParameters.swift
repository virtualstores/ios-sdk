//
//  TriggerEventsParameters.swift
//  
//
//  Created by Théodore Roos on 2022-04-11.
//

import Foundation

struct TriggerEventsParameters {
  let storeId: Int64
  let config: EnvironmentConfig?
}
extension TriggerEventsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var method: RequestType { .GET }
  var path: String { "/triggerevents/messages" }
  var queryItems: [String : String]? { ["storeId": String(storeId)] }
}
