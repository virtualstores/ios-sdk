//
// ClientsList
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

public struct ClientsList: Codable {
    public let clients: [Client]

    public init(clients: [Client]) {
        self.clients = clients
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clients = try container.decode([Client].self, forKey: .clients)
    }
}
