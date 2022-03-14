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

    private var heading: TT2Course? {
        let north = positionKitManager.rtlsOption?.north ?? 0.0
        let heading = positionKitManager.locationHeadingPublisher.value
        let course = TT2Course(fromDegrees: -heading.magneticHeading + 90 - north)
        Logger(verbosity: .debug).log(message: "North: \(north)")
        Logger(verbosity: .debug).log(message: "Heading: \(heading)")
        Logger(verbosity: .debug).log(message: "Course: \(course.degrees)")
        return course
    }
    
    public init(positionManager: PositionManager) {
        self.positionKitManager = positionManager
    }
}

public extension Navigation {
    func start(startPosition: CGPoint, startAngle: Double) throws {
        guard !isActive else { throw PositionKitError.alreadyStarted }
        try positionKitManager.start()
        
        positionKitManager.startNavigation(with: startAngle,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: false)
        isActive = true
    }
    
    func start(code: PositionedCode) throws {
        guard !isActive else { throw PositionKitError.alreadyStarted } 
        try start(startPosition: code.point, startAngle: code.direction)
    }
    
    func syncPosition(position: ItemPosition, syncRotation: Bool, forceSync: Bool) throws {
        guard isActive else { return }

        let pointWithOffset = TT2PointWithOffset(point: position.point, offset: position.offsetPoint)
        
        positionKitManager.syncPosition(position: pointWithOffset, syncRotation: syncRotation, forceSync: forceSync, uncertainAngle: false)
    }
    
    func start(startPosition: CGPoint) throws {
        guard let heading = self.heading, !isActive else { throw PositionKitError.alreadyStarted }
        try positionKitManager.start()

        positionKitManager.startNavigation(with: heading.degrees,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: true)
        isActive = true
    }
    
    func syncPosition(position: ItemPosition) throws  {
        guard let heading = self.heading, isActive else { return }
        //degrees = degrees + 180

        let point = position.point
        let offset = CGPoint(x: point.x + cos(heading.radians), y: point.y + sin(heading.radians))
        Logger(verbosity: .debug).log(message: "Point: \(point)")
        Logger(verbosity: .debug).log(message: "Offset: \(offset)")
        Logger(verbosity: .debug).log(message: "Direction: \(positionKitManager.directionPublisher.value?.angle)")
        let pointWithOffset = TT2PointWithOffset(point: point, offset: offset)
        
        positionKitManager.syncPosition(position: pointWithOffset, syncRotation: true, forceSync: true, uncertainAngle: true)
    }
    
    func stop() {
        positionKitManager.stop()
        isActive = false
    }

    func prepareAngle() { }
}
