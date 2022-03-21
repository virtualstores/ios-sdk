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
        return course
    }

    private var userStartAngle: TT2Course = TT2Course(fromRadians: 0.0)

    public init(positionManager: PositionManager) {
        self.positionKitManager = positionManager
    }
}

public extension Navigation {

    func start(startPosition: CGPoint, startAngle: Double) throws {
        guard !isActive else {
            self.stop()
            try self.start(startPosition: startPosition)
            return
        }

        try positionKitManager.start()

        positionKitManager.startNavigation(with: startAngle,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: false)
        isActive = true
        userStartAngle = TT2Course(fromDegrees: startAngle)
    }

    func start(code: PositionedCode) throws {
        try start(startPosition: code.point, startAngle: code.direction)
    }

    func syncPosition(position: ItemPosition, syncRotation: Bool, forceSync: Bool) throws {
        guard isActive else { return }

        let angle = atan2(-position.offsetPoint.y, -position.offsetPoint.x)*180.0/Double.pi

        positionKitManager.syncPosition(xPosition: position.point.x, yPosition: position.point.y, startAngle: angle, syncPosition: true, syncAngle: true, uncertainAngle: false)
    }

    func start(startPosition: CGPoint) throws {
        guard let heading = self.heading, !isActive else {
            self.stop()
            try self.start(startPosition: startPosition)
            return
        }

        try positionKitManager.start()

        positionKitManager.startNavigation(with: heading.degrees,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: true)
        isActive = true
        userStartAngle = heading
    }

    func syncPosition(position: ItemPosition) throws  {
        guard let heading = self.heading, isActive else { return }

        positionKitManager.syncPosition(xPosition: position.point.x, yPosition: position.point.y, startAngle: heading.degrees, syncPosition: true, syncAngle: true, uncertainAngle: true)
    }

    func stop() {
        positionKitManager.stop()
        isActive = false
    }

    func prepareAngle() { }
}

extension Navigation {
    func changeFloorStart(startPosition: CGPoint) throws {
        guard isActive else { return }

        try positionKitManager.start()

        positionKitManager.startNavigation(with: userStartAngle.degrees,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: false)
    }

    func changeFloorStop() {
        positionKitManager.stop(stopSensors: false)
    }
}
