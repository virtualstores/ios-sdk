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
    @Inject var positionKitManager: PositionManager
    @Inject var floor: VSTT2FloorManager
    @Inject var positionManager: Position
    @Inject var modelManager: VSMLModelManager

    public var currentPosition: CGPoint?
    public private(set) var isActive: Bool = false {
        didSet {
            isActivePublisher.send(isActive)
        }
    }

    var isActivePublisher: CurrentValueSubject<Bool, Never> = .init(false)
    var accuracyPublisher: CurrentValueSubject<(event: AccuracySyncEvent.Event, isFloorSwap: Bool)?,Never> = .init(nil)

    var currentAccessPointPosition: CGPoint = .zero

    private var startCodes: [PositionedCode] = []
    private var hasStartLocationAngle: Bool = false
    private var certainAngle: Bool = false

    private var heading: TT2Course? {
        guard
          let north = positionKitManager.rtlsOption?.north,
          let heading = positionKitManager.locationHeadingPublisher.value
        else { return nil }
        return TT2Course(fromDegrees: -heading.magneticHeading + 90 - north)
    }

    private var userStartAngle: TT2Course = TT2Course(fromRadians: 0.0)

    var onValidateFloorCompletion: (() throws -> ())?
    func validateFloorLevel(floorId: Int64?, completion: @escaping (Bool) throws -> Void) throws {
      guard let floorId = floorId, let currentFloorId = floor.activeFloor?.id else { try completion(true); return }
      if currentFloorId == floorId {
        try completion(true)
      } else {
        guard let rtls = floor.floors.first(where: { $0.id == floorId }) else { return }
        onValidateFloorCompletion = { try completion(false); self.onValidateFloorCompletion = nil }
        floor.switchFloorPublisher.send((rtlsOptions: rtls, point: nil))
      }
    }
}

public extension Navigation {
    func start(startPosition: CGPoint, startAngle: Double) throws {
        guard modelManager.model != nil else { throw VSTT2Error.missingData }
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
        certainAngle = true
        positionKitManager.startNavigation(positions: [startPosition], syncPosition: true, syncAngle: true, angle: startAngle, uncertainAngle: false)
        isActive = true
        userStartAngle = TT2Course(fromDegrees: startAngle)
    }

    func start(code: PositionedCode) throws {
        try floor.floors.forEach {
            guard $0.scanLocations?.first(where: { $0.code == code.code }) != nil else { return }
            try validateFloorLevel(floorId: $0.id) { [self] (isValid) in
                try start(startPosition: code.point, startAngle: code.direction)
                prepareAccuracyUpload(code: code, isFloorSwap: !isValid)
            }
        }
    }

    func syncPosition(position: ItemPosition, syncRotation: Bool, forceSync: Bool) throws {
        let angle = atan2(-position.offset.dx, -position.offset.dy)*180.0/Double.pi
        guard isActive else {
          try start(startPosition: position.point, startAngle: angle)
          return
        }

        try validateFloorLevel(floorId: position.floorLevelId) { [self] (isValid) in
            prepareAccuracyUpload(position: position, isFloorSwap: !isValid)
            positionKitManager.syncPosition(positions: [position.pointWithOffset], syncPosition: !position.isDisabled, syncAngle: syncRotation, angle: angle, uncertainAngle: false)
        }
    }

    func start(startPosition: CGPoint, position: ItemPosition? = nil) throws {
        guard modelManager.model != nil, let heading = heading else { throw VSTT2Error.missingData }
        guard !isActive else {
            self.stop()
            var err: Error?
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              do {
                try self.start(startPosition: startPosition, position: position)
              } catch {
                err = error
              }
            }
            if let error = err { throw error }
            return
        }

        let startWithAngle = startWithAngle(startPosition: startPosition)
        try validateFloorLevel(floorId: position?.floorLevelId) { [self] (isValid) in
            try positionKitManager.start()
            positionKitManager.startNavigation(positions: [startPosition], syncPosition: true, syncAngle: true, angle: startWithAngle ?? heading.degrees, uncertainAngle: startWithAngle == nil)
            prepareAccuracyUpload(position: position, startDirection: heading.degrees, isFloorSwap: !isValid)
            isActive = true
            userStartAngle = heading
        }
    }

    func syncPosition(position: ItemPosition, forceSync: Bool = false) throws  {
        guard let heading = heading, isActive else {
            try self.start(startPosition: position.pointWithOffset, position: position)
            return
        }

        let point = position.pointWithOffset
        try validateFloorLevel(floorId: position.floorLevelId) { [self] (isValid) in
            prepareAccuracyUpload(position: position, isFloorSwap: !isValid)
            if let startLocationAngle = startWithAngle(startPosition: position.point) {
                positionKitManager.syncPosition(positions: [point], syncPosition: !position.isDisabled, syncAngle: true, angle: startLocationAngle, uncertainAngle: false)
            } else if certainAngle {
                try syncPosition(position: position, syncRotation: false, forceSync: true)
            } else {
                let syncingWithCompass = forceSync ? forceSync : doCompassStart(point: position.point) && !hasStartLocationAngle
                positionKitManager.syncPosition(positions: [point], syncPosition: !position.isDisabled, syncAngle: syncingWithCompass, angle: heading.degrees, uncertainAngle: syncingWithCompass)
            }
        }
    }

    func syncPosition(identifier: String, type: SyncTypeEnum, completion: @escaping (Result<Item,Error>) -> ()) {
        if let syncRotation = type.get().normal, syncRotation {
            prepareAngle()
        }
        positionManager.getBy(barcode: identifier) { (result) in
            switch result {
            case .success(let item):
                do {
                    if item.uniquePositions.isEmpty {
                        self.prepareAccuracyUpload(identifier: identifier)
                    } else if item.uniquePositions.count > 1 {
                        self.prepareAccuracyUpload(item: item)
                    } else if let position = item.itemPosition {
                        switch type {
                        case .compass(let forceSync):
                            try self.syncPosition(position: position, forceSync: forceSync)
                        case .normal(let syncRotation):
                            try self.syncPosition(position: position, syncRotation: syncRotation, forceSync: true)
                        }
                    }
                    completion(.success(item))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error): completion(.failure(error))
            }
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

    func prepareAngle() { positionKitManager.prepareAngle() }
}

extension Navigation {
    func setup(startCodes: [PositionedCode]) {
        self.startCodes = startCodes
    }

    func changeFloorStart(startPosition: CGPoint?) throws {
        guard let point = startPosition, isActive else { try onValidateFloorCompletion?(); return }

        try positionKitManager.start()

        positionKitManager.startNavigation(positions: [point], syncPosition: true, syncAngle: true, angle: userStartAngle.degrees, uncertainAngle: false)
    }

    func changeFloorStop() {
        guard isActive else { return }
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
    func prepareAccuracyUpload(position: ItemPosition? = nil, code: PositionedCode? = nil, startDirection: Double? = nil, identifier: String? = nil, item: Item? = nil, isFloorSwap: Bool = false) {
        var event: AccuracySyncEvent.Event?
        if let position = position {
            if let startDirection = startDirection {
                event = .startSyncEvent(AccuracySyncEvent.StartSyncEvent(itemPosition: position, startDirection: startDirection, didSync: !position.isDisabled))
            } else if let preScanLocation = currentPosition {
                event = .syncEvent(AccuracySyncEvent.SyncEvent(itemPosition: position, preSyncScanLocation: preScanLocation, didSync: !position.isDisabled))
            }
        } else if let code = code {
            event = .startLocationSyncEvent(AccuracySyncEvent.StartLocationSyncEvent(startScanLocation: code))
        } else if let identifier = identifier {
            event = .syncEventMissingPosition(AccuracySyncEvent.SyncEventMissingPosition(identifier: identifier))
        } else if let item = item {
            event = .syncEventMultipleItemPosition(AccuracySyncEvent.SyncEventMultipleItemPosition(item: item))
        }

        guard let event = event else { return }
        accuracyPublisher.send((event: event, isFloorSwap: isFloorSwap))
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
        guard let userPosition = currentPosition else { return false }
        let distance = point.distance(to: userPosition)
        return distance > 7
    }
}
