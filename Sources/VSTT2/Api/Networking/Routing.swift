//
// Routing
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

protocol Routing {

    /// Base url
    var baseURL: String { get }
    /// Request type
    var method: RequestType { get }
    /// Path for request
    var path: String { get }
    /// Needed parameters for request
    var parameters: [String: Any]? { get }
    /// Url encoding type
    var encoding: ParameterEncoding { get }
    /// Headers which can have the request
    var headers: [String: String]? { get }
    /// Final UrlRequest
    var urlRequest: URLRequest? { get }
    /// Environment config data
    var environmentConfig: EnvironmentConfig { get }
}

extension Routing {
    var environmentConfig: EnvironmentConfig { .development }

    var baseURL: String { environmentConfig.baseURL() }

    var method: RequestType { .GET }

    var path: String { "" }

    var parameters: [String: Any]? { nil }

    var encoding: ParameterEncoding { ParameterEncoding.json }

    var headers: [String: String]? { ["apiKey" : "kanelbulle"] }

    var urlRequest: URLRequest? {
        @Inject var logger: Logger

        let baseURLStirng = baseURL

        guard var url = URL(string: baseURLStirng) else {
            #if DEV
            logger.log(message: "cannot create URL")
            #endif

            return nil
        }

        if !path.isEmpty {
            url.appendPathComponent(path)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        if let headers = self.headers {
            for (key, value) in headers {
                urlRequest.addValue(value, forHTTPHeaderField: key)
            }
        }

        if let parameters = self.parameters {
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
