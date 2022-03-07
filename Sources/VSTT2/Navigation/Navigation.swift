//
// Navigation
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import VSFoundation
import VSPositionKit
import CoreGraphics
import UIKit

final public class Navigation: INavigation {
    public var positionKitManager: PositionManager
    public var isActive: Bool = false
    
    public init(positionManager: PositionManager) {
        self.positionKitManager = positionManager
    }
}

public extension Navigation {
    func start(startPosition: CGPoint, startAngel: Double) throws {
        try positionKitManager.start()
        
        positionKitManager.startNavigation(with: startAngel,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: false)
        isActive = true
    }
    
    func start(code: PositionedCode) throws {
        try start(startPosition: code.point, startAngel: code.direction)
    }
    
    func syncPosition(position: ItemPosition, syncRotation: Bool, forceSync: Bool) throws {
        guard isActive else { return }

        let pointWithOffset = TT2PointWithOffset(point: position.point, offset: position.offsetPoint)
        
        positionKitManager.syncPosition(position: pointWithOffset, syncRotation: syncRotation, forceSync: forceSync, uncertainAngle: false)
    }
    
    func compassStartNavigation(startPosition: CGPoint) throws {
        try positionKitManager.start()
        
        let north = positionKitManager.rtlsOption?.north ?? 0.0
        let heading = positionKitManager.locationHeadingPublisher.value
        let course = TT2Course(fromDegrees: -heading.magneticHeading + 90 - north)
        positionKitManager.startNavigation(with: course.degrees,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: true)
        isActive = true
    }
    
    func compassSyncPosition(position: ItemPosition) throws  {
        guard isActive else { return }

        let north = positionKitManager.rtlsOption?.north ?? 0.0
        let heading = positionKitManager.locationHeadingPublisher.value
        let course = TT2Course(fromDegrees: -heading.magneticHeading + 90 - north)
        let point = position.point
        let offset = CGPoint(x: point.x + cos(course.degrees), y: point.y + sin(course.degrees))
        let pointWithOffset = TT2PointWithOffset(point: point, offset: offset)
        
        positionKitManager.syncPosition(position: pointWithOffset, syncRotation: true, forceSync: true, uncertainAngle: true)
    }
    
    func stop() {
        positionKitManager.stop()
        isActive = false
    }

    func prepareAngle() { }
}
