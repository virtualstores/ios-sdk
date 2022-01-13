//
//  File.swift
//  
//
//  Created by Hripsime on 2022-01-13.
//

import Foundation

public struct ServerConnection: Codable {
    public let apiKey: String
    public let serverAddress: String
    public let mqttAddress: String
    public let storeId: Int64

    public init(apiKey: String?, serverAddress: String, mqttAddress: String, storeId: Int64) {
        self.apiKey = apiKey ?? ""
        self.serverAddress = serverAddress
        self.mqttAddress = mqttAddress
        self.storeId = storeId
    }
}
