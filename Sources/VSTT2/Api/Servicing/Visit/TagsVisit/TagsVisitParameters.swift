//
//  TagsVisitParameters.swift
//  
//
//  Created by Théodore Roos on 2022-12-07.
//

import Foundation

public struct TagsVisitParameters {
  private let config: EnvironmentConfig?
  private let requestId: String
  private let visitId: Int64
  private let tags: [String : String]

  public init(config: EnvironmentConfig?, requestId: String, visitId: Int64, tags: [String : String]) {
    self.config = config
    self.requestId = requestId
    self.visitId = visitId
    self.tags = tags
  }
}

extension TagsVisitParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

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
