//
//  Login.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-01-30.
//

import Combine
import VSFoundation

final class LoginService: DataFetchingManager {
  func call(with parameters: LoginParameters) -> AnyPublisher<LoginDto, Error> {
    execute(parameters, errorType: Error.self)
  }
}

struct LoginParameters {
  @Inject var config: EnvironmentConfig
  let username: String
  let password: String
}

extension LoginParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType? { .central }
  var method: RequestType { .POST }
  var path: String { "/auth/login" }
  var parameters: Any? {
    [
      "username": username,
      "password": password
    ]
  }
}
