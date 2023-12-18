//
// EnvironmentConfig
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

/// Here we can have all setups depended what we need to use for each environment
class EnvironmentConfig {
    enum EndPoints: String {
        case v1 = "api/v1"
        case v2 = "api/v2"
    }

    private var _centralServerConnection: ServerConnection?
    var centralServerConnection: ServerConnection {
        set { _centralServerConnection = newValue }
        get {
            guard let config = _centralServerConnection else { fatalError("ServerConnection not initialized") }
            return config
        }
    }
    
    private var _analyticsServerConnection: ServerConnection?
    var analyticsServerConnection: ServerConnection {
        set { _analyticsServerConnection = newValue }
        get {
            guard let config = _analyticsServerConnection else { fatalError("ServerConnection not initialized") }
            return config
        }
    }

    func initCentralServerConnection(with url: String, endPoint: EndPoints, apiKey: String) {
      if url.last == "/" {
        centralServerConnection = ServerConnection(apiKey: apiKey, serverAddress: url + endPoint.rawValue)
      } else {
        centralServerConnection = ServerConnection(apiKey: apiKey, serverAddress: url + "/" + endPoint.rawValue)
      }
    }
    
    func initAnalyticsServerConnection(with url: String, endPoint: EndPoints, apiKey: String) {
      if url.last == "/" {
        analyticsServerConnection = ServerConnection(apiKey: apiKey, serverAddress: url + endPoint.rawValue)
      } else {
        analyticsServerConnection = ServerConnection(apiKey: apiKey, serverAddress: url + "/" + endPoint.rawValue)
      }
    }
}
