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

    enum EndPoints: String {
        case v1 = "/api/v1"
        case v2 = "/api/v2"
    }

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
     
    func initCentralServerConnection(with url: String, endPoint: EndPoints, apiKey: String) {
        self._centralServerConnection = ServerConnection(apiKey: apiKey, serverAddress: url + endPoint.rawValue, mqttAddress: nil, storeId: nil)
    }
    
    func initAnalyticsServerConnection(with url: String, apiKey: String) {
        self._analyticsServerConnection = ServerConnection(apiKey: apiKey, serverAddress: url, mqttAddress: nil, storeId: nil)
    }
}
