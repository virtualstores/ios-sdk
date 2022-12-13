//
// Navigation
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import VSFoundation
import VSPositionKitTargets
import CoreGraphics
import UIKit

final public class Navigation: INavigation {
    public var currentPosition: CGPoint? { positionKitManager.positionPublisher.value?.position }
    public private(set) var isActive: Bool = false {
        didSet {
            isActivePublisher.send(isActive)
        }
    }

    private(set) var positionKitManager: PositionManager
    var isActivePublisher: CurrentValueSubject<Bool, Never> = .init(false)
    var accuracyPublisher: CurrentValueSubject<AccuracySyncEvent.Event?,Never> = .init(nil)

    var currentAccessPointPosition: CGPoint = .zero

    private var startCodes: [PositionedCode] = []
    private var hasStartLocationAngle: Bool = false

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
            var err: Error?
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              do {
                try self.start(startPosition: startPosition, startAngle: startAngle)
              } catch {
                err = error
              }
            }
            if let error = err { throw error }
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
        prepareAccuracyUpload(code: code)
    }

    func syncPosition(position: ItemPosition, syncRotation: Bool, forceSync: Bool) throws {
        guard isActive else { return }

        prepareAccuracyUpload(position: position)
        let angle = atan2(-position.offsetPoint.y, -position.offsetPoint.x)*180.0/Double.pi

        positionKitManager.syncPosition(xPosition: position.pointWithOffset.x, yPosition: position.pointWithOffset.y, startAngle: angle, syncPosition: forceSync, syncAngle: syncRotation, uncertainAngle: false)
    }

    func start(startPosition: CGPoint, position: ItemPosition? = nil) throws {
        guard let heading = self.heading, !isActive else {
            self.stop()
            var err: Error?
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              do {
                try self.start(startPosition: startPosition)
              } catch {
                err = error
              }
            }
            if let error = err { throw error }
            return
        }

        let startWithAngle = self.startWithAngle(startPosition: startPosition)
        try positionKitManager.start()

        positionKitManager.startNavigation(with: startWithAngle ?? heading.degrees,
                                           xPosition: startPosition.x,
                                           yPosition: startPosition.y,
                                           uncertainAngle: startWithAngle == nil)
        if let position = position {
            prepareAccuracyUpload(position: position, startDirection: heading.degrees)
        }
        isActive = true
        userStartAngle = heading
    }

    func syncPosition(position: ItemPosition, forceSync: Bool = false) throws  {
        guard let heading = self.heading, isActive else {
            try self.start(startPosition: position.pointWithOffset, position: position)
            return
        }

        let point = position.pointWithOffset
        prepareAccuracyUpload(position: position)
        if let startLocationAngle = self.startWithAngle(startPosition: position.point) {
            positionKitManager.syncPosition(xPosition: point.x, yPosition: point.y, startAngle: startLocationAngle, syncPosition: true, syncAngle: true, uncertainAngle: false)
        } else {
            let syncingWithCompass = forceSync ? forceSync : doCompassStart(point: position.point) && !hasStartLocationAngle
            positionKitManager.syncPosition(xPosition: point.x, yPosition: point.y, startAngle: heading.degrees, syncPosition: true, syncAngle: syncingWithCompass, uncertainAngle: syncingWithCompass)
        }
    }

    func syncPositionToNearestAccessPoint() throws {
        try start(startPosition: currentAccessPointPosition)
    }

    func stop() {
        positionKitManager.stop()
        hasStartLocationAngle = false
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

    func startRecording() {
        positionKitManager.startRecording()
    }

    func stopRecording() {
        positionKitManager.stopRecording()
    }
}

private extension Navigation {
    func prepareAccuracyUpload(position: ItemPosition? = nil, code: PositionedCode? = nil, startDirection: Double? = nil) {
        var event: AccuracySyncEvent.Event?
        if let position = position {
            if let startDirection = startDirection {
                event = .startSyncEvent(AccuracySyncEvent.StartSyncEvent(itemPosition: position, startDirection: startDirection))
            } else if let preScanLocation = positionKitManager.positionPublisher.value?.position {
                event = .syncEvent(AccuracySyncEvent.SyncEvent(itemPosition: position, preSyncScanLocation: preScanLocation))
            }
        } else if let code = code {
            event = .startLocationSyncEvent(AccuracySyncEvent.StartLocationSyncEvent(startScanLocation: code))
        }
        accuracyPublisher.send(event)
    }

    func startWithAngle(startPosition: CGPoint) -> Double? {
        guard
          let code = self.startCodes.first(where: { $0.code == "start/plasticbags" }),
          Int(code.point.x) == Int(startPosition.x),
          Int(code.point.y) == Int(startPosition.y)
        else { return nil }
        hasStartLocationAngle = true
        return code.direction
    }

    func doCompassStart(point: CGPoint) -> Bool {
        guard let userPosition = positionKitManager.positionPublisher.value?.position else { return false }
        let distance = point.distance(to: userPosition)
        return distance > 7
    }
}
