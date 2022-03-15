//
// BarcodePosition
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics

public struct BarcodePosition: Codable {
    public let rtlsOptionsId: Int64?
    public let shelfId: Int64?
    public let shelfTierId: Int64?
    public let barcode: String?
    public let itemPositionX: Double?
    public let itemPositionY: Double?
    public let itemPositionOffsetX: Double?
    public let itemPositionOffsetY: Double?

    public var itemPosition: CGPoint? {
        guard let x = itemPositionX, let y = itemPositionY else {
            return nil
        }

        return CGPoint(x: x, y: y)
    }

    public var itemPositionOffset: CGVector? {
        guard let x = itemPositionOffsetX, let y = itemPositionOffsetY else {
            return nil
        }

        return CGVector(dx: x, dy: y)
    }

    public init(rtlsOptionsId: Int64?, shelfId: Int64?, shelfTierId: Int64?, itemPositionX: Double?, itemPositionY: Double?, itemPositionOffsetX: Double?, itemPositionOffsetY: Double?, barcode: String?) {
        self.rtlsOptionsId = rtlsOptionsId
        self.shelfId = shelfId
        self.shelfTierId = shelfTierId
        self.barcode = barcode
        self.itemPositionX = itemPositionX
        self.itemPositionY = itemPositionY
        self.itemPositionOffsetX = itemPositionOffsetX
        self.itemPositionOffsetY = itemPositionOffsetY
    }
}
