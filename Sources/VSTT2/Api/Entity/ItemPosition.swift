//
// ItemPosition
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics

public struct ItemPosition: Codable {
    public let xPosition: Double
    public let yPosition: Double
    public let offsetX: Double
    public let offsetY: Double
    public let floorLevel: Int64?

    public init(xPosition: Double, yPosition: Double, offsetX: Double, offsetY: Double, floorLevel: Int64?) {
        self.xPosition = xPosition
        self.yPosition = yPosition
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.floorLevel = floorLevel
    }

    public init(point: CGPoint, offset: CGVector, floorLevel: Int64?) {
        self.xPosition = Double(point.x)
        self.yPosition = Double(point.y)
        self.offsetX = Double(offset.dx)
        self.offsetY = Double(offset.dy)
        self.floorLevel = floorLevel
    }

    public var point: CGPoint {
        CGPoint(x: xPosition, y: yPosition)
    }

    public var offset: CGVector {
        CGVector(dx: offsetX, dy: offsetY)
    }

    public var pointWithOffset: CGPoint {
        CGPoint(x: point.x + offset.dx, y: point.y + offset.dy)
    }
}
