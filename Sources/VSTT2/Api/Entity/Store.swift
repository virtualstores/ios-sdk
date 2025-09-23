//
// Store
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics
import VSFoundation

public struct Store: Codable {
    public let id: Int64
    public let externalId: String?
    public let clientId: Int64
    public let name: String
    public let address: Address
    public let latitude: Double
    public let longitude: Double
    public let active: Bool
    public let hasSensorRecordingActive: Bool
    public let hasWiFiRecordingActive: Bool
    public let startCodes: [PositionedCode]
    public let stopCodes: [PositionedCode]
    public let rtlsOptions: [RtlsOptions]
    public let minVersion: String?
    public let serverConnection: ServerConnection?
    public let statServerConnection: ServerConnection
    public let positionServiceSettings: PositionServiceSettings?
    public let syncPositionFilter: SyncFilter?
    public let syncCompassFilter: SyncFilter?
    public let acceptedScoreLimit: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case externalId
        case clientId
        case name
        case address
        case latitude
        case longitude
        case active
        case hasSensorRecordingActive
        case hasWiFiRecordingActive
        case startCodes = "startScanLocations"
        case stopCodes = "stopScanLocations"
        case rtlsOptions = "rtlsOptionsList"
        case minVersion
        case serverConnection
        case statServerConnection
        case positionServiceSettings
        case syncPositionFilter
        case syncCompassFilter
        case acceptedScoreLimit
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int64.self, forKey: .id)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        clientId = try container.decode(Int64.self, forKey: .clientId)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(Address.self, forKey: .address)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        active = try container.decode(Bool.self, forKey: .active)
        hasSensorRecordingActive = try container.decodeIfPresent(Bool.self, forKey: .hasSensorRecordingActive) ?? false
        hasWiFiRecordingActive = try container.decodeIfPresent(Bool.self, forKey: .hasWiFiRecordingActive) ?? false
        startCodes = try container.decodeIfPresent([PositionedCode].self, forKey: .startCodes) ?? []
        stopCodes = try container.decodeIfPresent([PositionedCode].self, forKey: .stopCodes) ?? []
        rtlsOptions = try container.decode([RtlsOptions].self, forKey: .rtlsOptions)
        minVersion = try container.decodeIfPresent(String.self, forKey: .minVersion)
        serverConnection = try container.decodeIfPresent(ServerConnection.self, forKey: .serverConnection)
        statServerConnection = try container.decode(ServerConnection.self, forKey: .statServerConnection)
        positionServiceSettings = try container.decodeIfPresent(PositionServiceSettings.self, forKey: .positionServiceSettings)
        syncPositionFilter = try container.decodeIfPresent(SyncFilter.self, forKey: .syncPositionFilter)
        syncCompassFilter = try container.decodeIfPresent(SyncFilter.self, forKey: .syncCompassFilter)
        acceptedScoreLimit = try container.decodeIfPresent(Int.self, forKey: .acceptedScoreLimit)
    }

    init(
        id: Int64,
        externalId: String?,
        clientId: Int64,
        name: String,
        address: Address,
        latitude: Double,
        longitude: Double,
        active: Bool,
        hasSensorRecordingActive: Bool,
        hasWiFiRecordingActive: Bool,
        startCodes: [PositionedCode],
        stopCodes: [PositionedCode],
        rtlsOptions: [RtlsOptions],
        minVersion: String?,
        serverConnection: ServerConnection?,
        statServerConnection: ServerConnection,
        positionServiceSettings: PositionServiceSettings?,
        syncPositionFilter: SyncFilter?,
        syncCompassFilter: SyncFilter?,
        acceptedScoreLimit: Int?
    ) {
        self.id = id
        self.externalId = externalId
        self.clientId = clientId
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.active = active
        self.hasSensorRecordingActive = hasSensorRecordingActive
        self.hasWiFiRecordingActive = hasWiFiRecordingActive
        self.startCodes = startCodes
        self.stopCodes = stopCodes
        self.rtlsOptions = rtlsOptions
        self.minVersion = minVersion
        self.serverConnection = serverConnection
        self.statServerConnection = statServerConnection
        self.positionServiceSettings = positionServiceSettings
        self.syncPositionFilter = syncPositionFilter
        self.syncCompassFilter = syncCompassFilter
        self.acceptedScoreLimit = acceptedScoreLimit
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

    static let mockStore: Store = .init(
        id: 1,
        externalId: nil,
        clientId: 1,
        name: "Mock Store",
        address: .init(city: nil, zipCode: nil, address: nil, description: nil),
        latitude: 0.0,
        longitude: 0.0,
        active: true,
        hasSensorRecordingActive: true,
        hasWiFiRecordingActive: true,
        startCodes: [],
        stopCodes: [],
        rtlsOptions: [.mockRtlsOptions],
        minVersion: nil,
        serverConnection: nil,
        statServerConnection: .init(apiKey: nil, serverAddress: nil),
        positionServiceSettings: .init(
            useML: false,
            useCoefficientOptimizer: false,
            useDriftCompensator: false,
            boolValues: ["ios_magnetometerDriftEstimatorParams_useMagnetometer": true],
            stringValues: nil,
            stringArrayValues: nil,
            intValues: nil,
            intArrayValues: nil,
            floatValues: [
                "ios_magnetometerDriftEstimatorParams_maxRate": 0.025,
                "ios_magnetometerDriftEstimatorParams_alpha": 0.99995,
                "ios_magnetometerDriftEstimatorParams_accLowerLimit": 0.8,
                "ios_magnetometerDriftEstimatorParams_accUpperLimit": 15,
                "ios_magnetometerDriftEstimatorParams_sigmaMag": 30,
                "ios_magnetometerDriftEstimatorParams_magExpectedNorm": 49.4
            ],
            floatArrayValues: nil
        ),
        syncPositionFilter: nil,
        syncCompassFilter: nil,
        acceptedScoreLimit: 500
    )
}
