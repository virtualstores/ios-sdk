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

enum RoutingType {
  case central, analytics, unknown
}

extension Routing {
    func getServerConnection() -> ServerConnection? {
        switch type {
        case .central: return environmentConfig?.centralServerConnection
        case .analytics: return environmentConfig?.analyticsServerConnection
        case .unknown: return nil
        }
    }

    var baseURL: String {
        guard let url = getServerConnection()?.serverAddress else { fatalError("baseURL is not exist") }
        return url
    }

    var parametersDictionary: [String: Any]? { nil }

    var parameters: Any? { nil }

    var queryItems: [String: String]? { nil }

    var encoding: ParameterEncoding { .json }

    var headers: [String: String]? {
        guard let apiKey = getServerConnection()?.apiKey else { fatalError("apiKey is not exist") }
        return  ["apiKey" : apiKey]
    }

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

        if let headers = headers {
          headers.forEach { (key, value) in
                urlRequest.addValue(value, forHTTPHeaderField: key)
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
