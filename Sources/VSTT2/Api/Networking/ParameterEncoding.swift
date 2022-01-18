//
// ParameterEncoding
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

enum RequestType: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

enum ParameterEncoding {
    case json

    // MARK: URL encoding
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
        }

        guard encodingError == nil else { throw encodingError! }
        return request
    }
}

extension Encodable {
    func asDictionary() -> [String: Any] {
        do {
            let data = try JSONEncoder().encode(self)
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw NSError()
            }
            return dictionary
        } catch {
            Logger.init(verbosity: .silent).log(message: error.localizedDescription)
        }

        return [:]
    }
}
