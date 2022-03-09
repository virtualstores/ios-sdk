//
// Store
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics
import VSFoundation

public struct TT2Store {
    public let id: Int64
    public let name: String
    public let address: Address
    public let latitude: Double
    public let longitude: Double
    public let active: Bool
    public let startScanLocations: [PositionedCode]
    public let stopScanLocations: [PositionedCode]
}
