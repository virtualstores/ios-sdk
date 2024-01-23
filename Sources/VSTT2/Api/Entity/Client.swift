//
// Client
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

public struct Client: Codable {
    public let clientId: Int64
    public let name: String?
    public let dataServerUrl: String?
    public let dataServerApiKey: String?

    public init(clientId: Int64, name: String?, dataServerUrl: String?, dataServerApiKey: String?) {
        self.clientId = clientId
        self.name = name
        self.dataServerUrl = dataServerUrl
        self.dataServerApiKey = dataServerApiKey
    }

    private enum CodingKeys: String, CodingKey {
        case clientId = "id"
        case name
        case dataServerUrl
        case dataServerApiKey
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        clientId = try container.decode(Int64.self, forKey: .clientId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        dataServerUrl = try container.decodeIfPresent(String.self, forKey: .dataServerUrl)
        dataServerApiKey = try container.decodeIfPresent(String.self, forKey: .dataServerApiKey)
    }
}
