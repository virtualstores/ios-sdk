//
// Store
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics

public final class Store: Codable {
    public let id: Int64
    public let name: String
    public let address: Address
    public let latitude: Double
    public let longitude: Double
    public let active: Bool
    private let startCodes: [PositionedCode]
    private let stopCodes: [PositionedCode]
    public let rtls: RTLS
    public let minVersion: String?

    public init(id: Int64, name: String, address: Address, latitude: Double, longitude: Double,
                active: Bool, startCodes: [PositionedCode], stopCodes: [PositionedCode], rtls: RTLS, minVersion: String?) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.active = active
        self.startCodes = startCodes
        self.stopCodes = stopCodes
        self.rtls = rtls
        self.minVersion = minVersion
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case latitude
        case longitude
        case active
        case startCodes = "startScanLocations"
        case stopCodes = "stopScanLocations"
        case rtls = "rtlsOptions"
        case minVersion
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
        rtls = try container.decode(RTLS.self, forKey: .rtls)
        minVersion = try container.decodeIfPresent(String.self, forKey: .minVersion)
    }
}
