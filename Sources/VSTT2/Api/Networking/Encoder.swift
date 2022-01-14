//
//  File.swift
//  
//
//  Created by Hripsime on 2022-01-14.
//

import Foundation

final class Encoder {
    public static func query(with parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(with: key, value: value)
        }

        return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
    }

    static func queryComponents(with key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(with: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(with: "\(key)[]", value: value)
            } } else {
            components.append((escape(with: key), escape(with: "\(value)")))
        }

        return components
    }

    static func escape(with key: String) -> String {
        let allowedCharacters =  CharacterSet(charactersIn: " =\"#%/<>?@\\^`{}[]|&+").inverted

        return key.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? key
    }
}
