//
// ServerConnection
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation

public struct ServerConnection: Codable {
    public let apiKey: String?
    public let serverAddress: String?
    public let mqttAddress: String?
    public let storeId: Int64?

    public init(apiKey: String?, serverAddress: String?, mqttAddress: String?, storeId: Int64?) {
        self.apiKey = apiKey ?? ""
        self.serverAddress = serverAddress
        self.mqttAddress = mqttAddress
        self.storeId = storeId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey)
        serverAddress = try container.decodeIfPresent(String.self, forKey: .serverAddress)
        mqttAddress = try container.decodeIfPresent(String.self, forKey: .mqttAddress)
        storeId = try container.decodeIfPresent(Int64.self, forKey: .storeId)

    }
}
