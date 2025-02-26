//
// Routing
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

protocol Routing {
    /// Environment config data
    var environmentConfig: EnvironmentConfig? { get }
    var type: RoutingType { get }
    var authType: AuthTypeEnum { get }
    /// Request type
    var method: RequestType { get }
    /// Base url
    var baseURL: String { get }
    /// Path for request
    var path: String { get }
    /// Needed parameters for request
    var parametersDictionary: [String: Any]? { get }

    var parameters: Any? { get }

    var queryItems: [String: String]? { get }

    /// Url encoding type
    var encoding: ParameterEncoding { get }
    /// Headers which can have the request
    var headers: [String: String]? { get }
    /// Final UrlRequest
    var urlRequest: URLRequest? { get }
}

public enum AuthTypeEnum: String {
  case apiKey = "API_KEY"
  case tokenBased = "TOKEN_BASED"
}

enum RoutingType {
  case central, analytics, ml, unknown
}

extension Routing {
    var getConnection: EnvironmentConfig.ServerSettings? {
      switch type {
      case .central: return environmentConfig?.connection.tt2CentralServer
      case .analytics: return environmentConfig?.connection.tt2DataServer
      case .ml: return environmentConfig?.connection.tt2MLModelServer
      case .unknown: return nil
      }
    }

    var authType: AuthTypeEnum { getConnection?.authType ?? .apiKey }

    var baseURL: String {
        guard let url = getConnection?.baseUrl else { fatalError("baseURL is not exist") }
        return url
    }

    var parametersDictionary: [String: Any]? { nil }

    var parameters: Any? { nil }

    var queryItems: [String: String]? { nil }

    var encoding: ParameterEncoding { .json }

    var headers: [String: String]? { nil }

    var urlRequest: URLRequest? {
        @Inject var logger: Logger

        guard var url = URL(string: baseURL) else {
            #if DEV
            logger.log(message: "cannot create URL")
            #endif

            return nil
        }

        if !path.isEmpty {
            url.appendPathComponent(path)
        }

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            #if DEV
            logger.log(message: "cannot create URLComponents")
            #endif
            return nil
        }

        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems.map({ URLQueryItem(name: $0.key, value: $0.value) })
        }

        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = method.rawValue

        switch authType {
        case .apiKey:
          if let request = urlRequest.apiKeyInterceptor(routing: type) {
            urlRequest = request
          }
        case .tokenBased:
          if let request = urlRequest.authTokenInterceptor() {
            urlRequest = request
          }
        }

        if let parameters = parametersDictionary {
            do {
                urlRequest = try encoding.encode(request: urlRequest, parameters: parameters)
            } catch {
                #if DEV
                logger.log(message: "parameters encoding issue")
                #endif
            }
        } else if let parameters = parameters {
          do {
              urlRequest = try encoding.encode(request: urlRequest, parameters: parameters)
          } catch {
              #if DEV
              logger.log(message: "parameters encoding issue")
              #endif
          }
        }
        return urlRequest
    }
}

private extension URLRequest {
  static let HEADER_AUTHORIZATION: String = "Authorization"
  static let TOKEN_TYPE: String = "Bearer"

  func apiKeyInterceptor(routing: RoutingType) -> URLRequest? {
    @Inject var repositoy: IApiKeyRepository
    guard let apiKey = repositoy.get(for: routing) else { return nil }
    var request = self
    request.addValue(apiKey, forHTTPHeaderField: "apiKey")
    return request
  }

  func authTokenInterceptor() -> URLRequest? {
    @Inject var repositoy: IJWTTokenRepository
    guard let token = repositoy.getAuthJWT() else { return nil }
    var request = self
    request.addValue("\(URLRequest.TOKEN_TYPE) \(token)", forHTTPHeaderField: URLRequest.HEADER_AUTHORIZATION)
    return request
  }

  func refreshTokenInterceptor() -> URLRequest? {
    @Inject var repositoy: IJWTTokenRepository
    guard let token = repositoy.getRefreshJWT() else { return nil }
    var request = self
    request.addValue("\(URLRequest.TOKEN_TYPE) \(token)", forHTTPHeaderField: URLRequest.HEADER_AUTHORIZATION)
    return request
  }
}
