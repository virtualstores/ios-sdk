//
// Map
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation

public struct Map {
    public let id: Int64
    public let mapURL: String
    public let storeId: Int64
    public let railScale: Int
    public let pixelOffsetX: Int
    public let pixelOffsetY: Int
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(id: Int64, mapURL: String, storeId: Int64, railScale: Int, pixelOffsetX: Int, pixelOffsetY: Int, pixelWidth: Int, pixelHeight: Int) {
        self.id = id
        self.mapURL = mapURL
        self.storeId = storeId
        self.railScale = railScale
        self.pixelOffsetX = pixelOffsetX
        self.pixelOffsetY = pixelOffsetY
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}
