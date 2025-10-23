//
//  Refresh.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-01-30.
//

import Combine
import VSFoundation

final class RefreshService: DataFetchingManager {
  func call(with parameters: RefreshParameters) -> AnyPublisher<RefreshDto, Error> {
    execute(parameters, errorType: Error.self)
  }
}

struct RefreshParameters {
  @Inject var config: EnvironmentConfig
  let authToken: String
  let refreshToken: String
}

extension RefreshParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType? { .central }
  var method: RequestType { .POST }
  var path: String { "/auth/refresh" }
  var parameters: Any? {
    [
      "authToken": authToken,
      "refreshToken": refreshToken
    ]
  }
}
