//
// EnvironmentConfig
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

/// Here we can have all setups depended what we need to use for each environment
public class EnvironmentConfig {
  enum EndPoints: String {
    case v1 = "api/v1"
    case v2 = "api/v2"
  }

  private var _connection: Settings?
  var connection: Settings {
    set { _connection = newValue }
    get {
      guard let connection = _connection else { fatalError("ServerConnection not initialized") }
      return connection
    }
  }

  func set(connection: Settings) {
    _connection = connection
  }
}

public extension EnvironmentConfig {
  protocol Settings {
    var authType: AuthTypeEnum { get }
    var tt2CentralServer: ServerSettings { get }
    var tt2DataServer: ServerSettings? { get set }
    var tt2MLModelServer: ServerSettings? { get set }
    var tt2ResourceUrl: String? { get set }
    var tt2MLResourceUrl: String? { get set }
  }

  struct Direct: Settings {
    public let authType: AuthTypeEnum
    public let tt2CentralServer: ServerSettings
    public var tt2DataServer: ServerSettings?
    public var tt2MLModelServer: ServerSettings?
    public var tt2ResourceUrl: String?
    public var tt2MLResourceUrl: String?

    public init(authType: AuthTypeEnum, tt2CentralServer: String, tt2DataServer: String? = nil) {
      self.authType = authType
      self.tt2CentralServer = .init(
        baseUrl: tt2CentralServer
          .trimmingCharacters(in: .init(charactersIn: "/"))
          .appending("/")
          .appending(EndPoints.v1.rawValue),
        authType: authType
      )
      if let url = tt2DataServer {
        self.tt2DataServer = .init(
          baseUrl: url
            .trimmingCharacters(in: .init(charactersIn: "/"))
            .appending("/")
            .appending(EndPoints.v2.rawValue),
          authType: authType
        )
      }

      tt2MLModelServer = .init(baseUrl: "https://lmz7vrr223.execute-api.eu-north-1.amazonaws.com", authType: .apiKey)
    }
  }

  struct Gateway: Settings {
    public let authType: AuthTypeEnum
    public let tt2CentralServer: ServerSettings
    public var tt2DataServer: ServerSettings?
    public var tt2MLModelServer: ServerSettings?
    public var tt2ResourceUrl: String?
    public var tt2MLResourceUrl: String?

    public init(baseUrl: String, authType: AuthTypeEnum) {
      self.authType = authType
      let url = baseUrl.trimmingCharacters(in: .init(charactersIn: "/"))
      tt2CentralServer = ServerSettings(
        baseUrl: url.appending("/central/").appending(EndPoints.v1.rawValue),
        authType: authType
      )
      tt2DataServer = ServerSettings(
        baseUrl: url.appending("/data/").appending(EndPoints.v2.rawValue),
        authType: authType
      )
      tt2MLModelServer = ServerSettings(
        baseUrl: url.appending("/lambda"),
        authType: .apiKey
      )
      tt2ResourceUrl = url.appending("/s3")
      tt2MLResourceUrl = url.appending("/ml")
    }
  }

  struct ServerSettings {
    public let baseUrl: String
    public let authType: AuthTypeEnum
  }
}
