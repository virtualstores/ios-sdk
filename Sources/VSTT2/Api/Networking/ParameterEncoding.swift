//
// ParameterEncoding
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation

enum RequestType: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

enum ParameterEncoding {
    case json
    case url
    case urlEncodedInURL

  // URL encoding
    func encode(request: URLRequest, parameters: [String: Any]?) throws -> URLRequest {
        guard let parameters = parameters else { return request }

        var request = request
        var encodingError: NSError?

        switch self {
        case .json:
            do {
                let options = JSONSerialization.WritingOptions()
                let data = try JSONSerialization.data(withJSONObject: parameters, options: options)

                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }

                request.httpBody = data
            } catch {
                encodingError = error as NSError
            }
        case .url, .urlEncodedInURL:
            if let httpMethod = request.httpMethod, let method = RequestType(rawValue: httpMethod), encodesURLParameters(for: method) {
                if let components = NSURLComponents(url: request.url!, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                    let percentEncodedQuery = (components.percentEncodedQuery.map { $0 + "&" } ?? "") + Encoder.query(with: parameters)
                    components.percentEncodedQuery = percentEncodedQuery
                    request.url = components.url
                }
            } else {
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue( "application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                }

                request.httpBody = Encoder.query(with: parameters).data(using: String.Encoding.utf8, allowLossyConversion: false)
            }
        }

        guard encodingError == nil else { throw encodingError! }
        return request
    }

    private func encodesURLParameters(for method: RequestType) -> Bool {
        switch self {
        case .urlEncodedInURL:
            return true
        default:
            break
        }

        switch method {
        case .GET, .DELETE:
            return true
        default:
            return false
        }
    }
}
