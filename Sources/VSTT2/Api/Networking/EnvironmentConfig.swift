//
// EnvironmentConfig
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

/// Here we can have all setups depended what we need to use for each environment
public class EnvironmentConfig {
    private var _centralServerConnection: ServerConnection?
    public var centralServerConnection: ServerConnection {
        get {
            guard let config = _centralServerConnection else { fatalError("ServerConnection not initialized") }

            return config
        }
    }
    
    private var _analyticsServerConnection: ServerConnection?
    public var analyticsServerConnection: ServerConnection {
        get {
            guard let config = _analyticsServerConnection else { fatalError("ServerConnection not initialized") }

            return config
        }
    }
     
    func initCentralServerConnection(with url: String, apiKey: String) {
        self._centralServerConnection = ServerConnection(apiKey: apiKey, serverAddress: url, mqttAddress: nil, storeId: nil)
    }
    
    func initAnalyticsServerConnection(with url: String, apiKey: String) {
        self._analyticsServerConnection = ServerConnection(apiKey: apiKey, serverAddress: url, mqttAddress: nil, storeId: nil)
    }
}
