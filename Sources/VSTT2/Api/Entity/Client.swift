//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-20.
//

import Foundation

public final class Client: Codable {
    public let clientId: String
    public let name: String?

    public init(clientId: String, name: String?) {
        self.clientId = clientId
        self.name = name
    }

    private enum CodingKeys: String, CodingKey {
        case clientId = "id"
        case name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        clientId = try String(container.decode(Int.self, forKey: .clientId))
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }
}
