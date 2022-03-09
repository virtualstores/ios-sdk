//
// AreaTrigger
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import VSFoundation
import UIKit

public struct AreaTrigger {
    var id: String
    var enabled: Bool
    var filterEvents: Bool
}

public protocol EventArea {
    func intersects(point: TT2Position) -> Bool
}

public protocol AreaEvent {
    var area: EventArea { get }
    var asPointOfInterest: PointOfInterest { get }
}

extension CGRect: EventArea {
    public func intersects(point: TT2Position) -> Bool {
        self.contains(CGPoint(x: point.xPosition, y: point.yPosition))
    }
}

extension UIBezierPath: EventArea {
    public func intersects(point: TT2Position) -> Bool {
        self.contains(CGPoint(x: point.xPosition, y: point.yPosition))
    }
}
