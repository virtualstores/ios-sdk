//
// Store
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics

public struct Store: Codable {
    public let id: Int64
    public let name: String
    public let address: Address
    public let latitude: Double
    public let longitude: Double
    public let active: Bool
    public let startCodes: [PositionedCode]
    public let stopCodes: [PositionedCode]
    public let rtlsOptions: [RtlsOptions]
    public let minVersion: String?
    public let serverConnection: ServerConnection
    public let statServerConnection: ServerConnection

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case latitude
        case longitude
        case active
        case startCodes = "startScanLocations"
        case stopCodes = "stopScanLocations"
        case rtlsOptions = "rtlsOptionsList"
        case minVersion
        case serverConnection
        case statServerConnection
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(Address.self, forKey: .address)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        active = try container.decode(Bool.self, forKey: .active)
        startCodes = try container.decode([PositionedCode].self, forKey: .startCodes)
        stopCodes = try container.decode([PositionedCode].self, forKey: .stopCodes)
        rtlsOptions = try container.decode([RtlsOptions].self, forKey: .rtlsOptions)
        minVersion = try container.decodeIfPresent(String.self, forKey: .minVersion)
        serverConnection = try container.decode(ServerConnection.self, forKey: .serverConnection)
        statServerConnection = try container.decode(ServerConnection.self, forKey: .statServerConnection)
    }

    public func getCodesFor(type: PositionedCode.CodeType, floorLevel: Int) -> [PositionedCode] {
        guard let rtls = rtlsOptions.first(where: { $0.floorLevel == floorLevel }), let scanLocations = rtls.scanLocations, scanLocations.count > 0 else {
            switch type {
            case .start: return self.startCodes
            case .stop: return self.stopCodes
            }
        }

        return scanLocations.all(where: { $0.type == type })
    }
}
