//
// ItemPosition
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics

public struct ItemPosition: Codable {
    public let x: Double
    public let y: Double
    public let offsetX: Double
    public let offsetY: Double
    
    public init(x: Double, y: Double, offsetX: Double, offsetY: Double) {
        self.x = x
        self.y = y
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
    
    public init(point: CGPoint, offset: CGVector) {
        self.x = Double(point.x)
        self.y = Double(point.y)
        self.offsetX = Double(offset.dx)
        self.offsetY = Double(offset.dy)
    }
    
    public var point: CGPoint {
        CGPoint(x: x, y: y)
    }
    
    public var offset: CGVector {
        CGVector(dx: offsetX, dy: offsetY)
    }
    
    public var pointWithOffset: CGPoint {
        CGPoint(x: point.x + offset.dx, y: point.y + offset.dy)
    }
}
