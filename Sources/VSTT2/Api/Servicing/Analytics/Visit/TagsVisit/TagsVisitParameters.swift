//
//  TagsVisitParameters.swift
//  
//
//  Created by Théodore Roos on 2022-12-07.
//

import Foundation
import VSFoundation

struct TagsVisitParameters {
  @Inject var config: EnvironmentConfig
  let requestId: String
  let visitId: Int64
  let tags: [String : String]
}

extension TagsVisitParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .analytics }
  var method: RequestType { .PUT }
  var path: String { "/visits/tags" }
  var queryItems: [String : String]? {
    [
      "requestId": requestId,
      "visitId": String(visitId)
    ]
  }

  var parametersDictionary: [String : Any]? {
    tags.asDictionary()
  }
}
