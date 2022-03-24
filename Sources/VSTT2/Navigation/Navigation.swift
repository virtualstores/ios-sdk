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

    private var startCodes: [PositionedCode] = []
    private var hasStartLocationAngle: Bool = false

    var accuracyPublisher: CurrentValueSubject<(preScanLocation: CGPoint, scanLocation: CGPoint, offset: CGVector)?,Never> = .init(nil)

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

        prepareAccuracyUpload(offset: position.offset)
        let angle = atan2(-position.offsetPoint.y, -position.offsetPoint.x)*180.0/Double.pi

        positionKitManager.syncPosition(xPosition: position.point.x, yPosition: position.point.y, startAngle: angle, syncPosition: forceSync, syncAngle: syncRotation, uncertainAngle: false)
    }

    func start(startPosition: CGPoint) throws {
        guard let heading = self.heading, !isActive else {
            self.stop()
            try self.start(startPosition: startPosition)
            return
        }

        let startWithAngle = self.startWithAngle(startPosition: startPosition)
        try positionKitManager.start()

        positionKitManager.startNavigation(with: startWithAngle ?? heading.degrees,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: startWithAngle == nil)
        isActive = true
        userStartAngle = heading
    }

    func syncPosition(position: ItemPosition) throws  {
        guard let heading = self.heading, isActive else {
            try self.start(startPosition: position.point)
            return
        }

        let point = position.pointWithOffset
        prepareAccuracyUpload(offset: position.offset)
        if let startLocationAngle = self.startWithAngle(startPosition: position.point) {
            positionKitManager.syncPosition(xPosition: point.x, yPosition: point.y, startAngle: startLocationAngle, syncPosition: true, syncAngle: true, uncertainAngle: false)
        } else {
            let syncingWithCompass = doCompassStart(point: position.point) && !hasStartLocationAngle
            print("Syncingwithcompass: \(syncingWithCompass)")
            positionKitManager.syncPosition(xPosition: point.x, yPosition: point.y, startAngle: heading.degrees, syncPosition: true, syncAngle: syncingWithCompass, uncertainAngle: syncingWithCompass)
        }
    }

    func stop() {
        positionKitManager.stop()
        self.hasStartLocationAngle = false
        isActive = false
    }

    func prepareAngle() { }
}

extension Navigation {
    func setup(startCodes: [PositionedCode]) {
        self.startCodes = startCodes
    }

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

private extension Navigation {
    func prepareAccuracyUpload(offset: CGVector) {
        guard let preScanLocation = positionKitManager.positionPublisher.value?.position else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let scanLocation = self.positionKitManager.positionPublisher.value?.position else { return }
            self.accuracyPublisher.send((preScanLocation: preScanLocation, scanLocation: scanLocation, offset: offset))
        }
    }

    func startWithAngle(startPosition: CGPoint) -> Double? {
        guard
          let code = self.startCodes.first(where: { $0.code == "start/plasticbags" }),
          Int(code.point.x) == Int(startPosition.x),
          Int(code.point.y) == Int(startPosition.y)
        else { return nil }
        self.hasStartLocationAngle = true
        return code.direction
    }

    func doCompassStart(point: CGPoint) -> Bool {
        guard let userPosition = positionKitManager.positionPublisher.value?.position else { return false }

        let distance = point.distance(to: userPosition)

        return distance > 7
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(self.x - point.x, 2) + pow(self.y - point.y, 2))
    }
}
