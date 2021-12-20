//
// Routing
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation

protocol Routing {

    /// Base url
    var baseURLString: String { get }
    ///Request type
    var method: RequestType { get }
    ///Path for request
    var routPath: String { get }
    ///Needed parameters for request
    var parameters: [String: Any]? { get }
    ///Url encoding type
    var encoding: ParameterEncoding { get }
    ///Headers which can have the request
    var headers: [String: String]? { get }
    ///Final UrlRequest
    var urlRequest: URLRequest? { get }
}

extension Routing {
    var baseURLString: String {
        return "https://baseurl"
    }

    var method: RequestType {
        return .POST
    }

    var routPath: String {
        return ""
    }

    var parameters: [String: Any]? {
        return nil
    }

    var encoding: ParameterEncoding {
        return ParameterEncoding.json
    }

    var headers: [String: String]? {
        return nil
    }

    var urlRequest: URLRequest? {
        let baseURLStirng = baseURLString

        guard var url = URL(string: baseURLStirng) else {
            #if DEV
            print("cannot create URL")
            #endif

            return nil
        }

        if !routPath.isEmpty {
            url.appendPathComponent(routPath)
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
                print("parameters encoding issue")
                #endif
            }
        }

        return urlRequest
    }
}

