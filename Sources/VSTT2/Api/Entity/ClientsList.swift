//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-20.
//

import Foundation

public final class ClientsList: Codable {
    public let clients: [Client]

    public init(clients: [Client]) {
        self.clients = clients
    }

    private enum CodingKeys: String, CodingKey {
        case clients
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clients = try container.decode([Client].self, forKey: .clients)
    }
}
