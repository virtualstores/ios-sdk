//
// RTLS
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics

public struct RTLS: Codable {
    public let id: Int64
    private let width: Double
    private let height: Double
    private let widthInMeters: Double
    private let heightInMeters: Double
    public let floorLevel: Int
    public let north: Double?
    public let name: String?
    public let startOffsetX: Double
    public let startOffsetY: Double
    public let mapBoxUrl: String?
    public let mapBoxToken: String?
    public let mapFenceUrl: String?
    public let mapZonesUrl: String?
    public let navGraphUrl: String?
    public let mapOffsetsUrl: String?
    public let mapDataVersionUrl: String?
    public let mapBoxImageUrl: String?
    public let scanLocations: [PositionedCode]?

    public init(id: Int64, width: Int64, height: Int64, widthInMeters: Double, heightInMeters: Double, floorLevel: Int?,
                north: Double?, name: String?, startOffsetX: Int64, startOffsetY: Int64, mapBoxUrl: String,
                mapBoxToken: String, mapFenceUrl: String, mapZonesUrl: String, navGraphUrl: String, mapOffsetsUrl: String,
                mapDataVersionUrl: String, mapBoxImageUrl: String, scanLocations: [PositionedCode]) {
        self.id = id
        self.width = Double(width)
        self.height = Double(height)
        self.widthInMeters = widthInMeters
        self.heightInMeters = heightInMeters
        self.floorLevel = floorLevel ?? 0
        self.north = north
        self.name = name
        self.startOffsetX = Double(startOffsetX)
        self.startOffsetY = Double(startOffsetY)
        self.mapBoxUrl = mapBoxUrl
        self.mapBoxToken = mapBoxToken
        self.mapFenceUrl = mapFenceUrl
        self.mapZonesUrl = mapZonesUrl
        self.navGraphUrl = navGraphUrl
        self.mapOffsetsUrl = mapOffsetsUrl
        self.mapDataVersionUrl = mapDataVersionUrl
        self.mapBoxImageUrl = mapBoxImageUrl
        self.scanLocations = scanLocations
    }
}
