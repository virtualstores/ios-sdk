//
// Navigation
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import CoreLocation
import Foundation
import Combine
import VSFoundation
import VSPositionKit
import UIKit

final public class Navigation {
    @Inject var vpsPosition: VPSPositionManager
    @Inject var floorManager: VSTT2FloorManager
    @Inject var positionManager: Position
    @Inject var modelManager: VSMLModelManager

    @Inject var vpsUpdates: SubscribeToVPSUpdatesUseCase
    @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
    @Inject var setIsVPSRunning: SetIsVPSRunningUseCase

    var activeFloor: RtlsOptions {
        @Inject var activeFloor: GetActiveFloorUseCase
        return activeFloor.invoke()
    }

    var floors: [RtlsOptions] {
        @Inject var getFloors: GetCachedFloorsUseCase
        return getFloors.invoke()
    }

    var isAutoFloorChangeEanbled: Bool {
      getTT2Settings.invoke().isAutomaticFloorChangeEnabled
    }

    @Inject var getPosition: GetCurrentVPSPositionUseCase
    public var currentPosition: CGPoint? { getPosition.invoke()?.point }

    @Inject var vpsPositionPublisher: SubscribeToVPSUpdatesUseCase
    public var positionPublisher: AnyPublisher<VPSOutputSignal.Position?, Never> { vpsPositionPublisher.invoke() }

    var accuracyPublisher: CurrentValueSubject<(event: AccuracySyncEvent.Event, isFloorSwap: Bool)?,Never> = .init(nil)
    var scanEventsPublisher: CurrentValueSubject<[ScanEvent]?, Never> = .init(nil)

    var currentAccessPointPosition: CGPoint = .zero
    var inAndOutZone: InAndOutZone?

    private var startCodes: [PositionedCode] { activeFloor.scanLocations?.filter({ $0.type == .start }) ?? [] }
    private var hasStartLocationAngle: Bool = false
    private var certainAngle: Bool = false
    private var cancellable = Set<AnyCancellable>()

    private var heading: TT2Course? {
        guard
          let north = vpsPosition.rtlsOption?.north,
          let heading = vpsPosition.locationHeadingPublisher.value?.headingDirection
        else { return nil }
        //let heading = VPSCompassHeadingController.trueHeading.value
        return TT2Course(fromDegrees: -heading + 90 - north)
    }

    private var userStartAngle: TT2Course = TT2Course(fromRadians: 0.0)

    var onValidateFloorCompletion: (() throws -> ())?
    func validateFloorLevel(floorId: Int64?, completion: @escaping (Bool) throws -> Void) throws {
      guard let floorId = floorId else { try completion(true); return }
      if activeFloor.id == floorId {
        try completion(true)
      } else {
        guard let rtls = floors.first(where: { $0.id == floorId }) else { return }
        onValidateFloorCompletion = { try completion(false); self.onValidateFloorCompletion = nil }
        floorManager.switchFloorPublisher.send((rtlsOptions: rtls, point: nil))
      }
    }
}

// MARK: INavigation
extension Navigation: INavigation {
    public var isActive: Bool {
      @Inject var isVPSRunning: GetIsVPSRunningUseCase
      return isVPSRunning.invoke()
    }
    public var compassHeading: Double? { heading?.degrees }

    /// Start Positioning System
    public func start(startPosition: CGPoint, startAngle: Double) throws {
        guard modelManager.mlModel != nil, modelManager.mlParams != nil else { throw VSTT2Error.missingData }
        guard !isActive else {
//            self.stop()
//            var err: Error?
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//              do {
//                try self.start(startPosition: startPosition, startAngle: startAngle)
//              } catch {
//                err = error
//              }
//            }
//            if let error = err { throw error }
            forceSyncPosition(position: startPosition, angle: startAngle)
            return
        }

        try vpsPosition.start(withoutAltimeter: !isAutoFloorChangeEanbled)
        certainAngle = true
        vpsPosition.startNavigation(positions: [startPosition], syncPosition: true, syncAngle: true, angle: startAngle, uncertainAngle: false)
        setIsVPSRunning.invoke(isVPSRunning: true, qrStart: true)
        userStartAngle = TT2Course(fromDegrees: startAngle)
    }

    public func start(code: PositionedCode) throws {
        try floors.forEach {
            guard $0.scanLocations?.first(where: { $0.code == code.code }) != nil else { return }
            try validateFloorLevel(floorId: $0.id) { [weak self] (isValid) in
                guard let self = self else { return }
                //if isActive {
                //    vpsPosition.forceSyncPosition(position: code.point, angle: code.direction)
                //} else {
                    try start(startPosition: code.point, startAngle: code.direction)
                //}
                prepareAccuracyUpload(code: code, isFloorSwap: !isValid)
            }
        }
    }

    public func syncPosition(position: ItemPosition, syncRotation: Bool, forceSync: Bool) throws {
        let angle = atan2(-position.offset.dy, -position.offset.dx).radiansToDegrees
        guard isActive else {
          try start(startPosition: position.point, startAngle: angle)
          prepareAccuracyUpload(position: position, startDirection: angle)
          return
        }

        try validateFloorLevel(floorId: position.floorLevelId) { [weak self] (isValid) in
            guard let self = self else { return }
            prepareAccuracyUpload(position: position, isFloorSwap: !isValid)
            vpsPosition.syncPosition(positions: [position.pointWithOffset], syncPosition: !position.isDisabled, syncAngle: syncRotation, angle: angle, uncertainAngle: false)
        }
    }

    /// Start Positioning System with Compass angle
    public func start(startPosition: CGPoint, position: ItemPosition? = nil) throws {
        guard modelManager.mlModel != nil, modelManager.mlParams != nil, let heading = heading else { throw VSTT2Error.missingData }
        guard !isActive else {
//            self.stop()
//            var err: Error?
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//              do {
//                try self.start(startPosition: startPosition, position: position)
//              } catch {
//                err = error
//              }
//            }
//            if let error = err { throw error }
            forceSyncPosition(position: startPosition, angle: heading.degrees)
            return
        }

        let startWithAngle = startWithAngle(startPosition: startPosition)
        try validateFloorLevel(floorId: position?.floorLevelId) { [weak self] (isValid) in
            guard let self = self else { return }
            try vpsPosition.start(withoutAltimeter: !isAutoFloorChangeEanbled)
            vpsPosition.startNavigation(positions: [startPosition], syncPosition: true, syncAngle: true, angle: startWithAngle ?? heading.degrees, uncertainAngle: startWithAngle == nil)
            prepareAccuracyUpload(position: position, startDirection: heading.degrees, isFloorSwap: !isValid)
            setIsVPSRunning.invoke(isVPSRunning: true, qrStart: false)
            userStartAngle = heading
        }
    }

    public func syncPosition(position: ItemPosition, forceSync: Bool = false) throws  {
        guard let heading = heading, isActive else {
            try start(startPosition: position.pointWithOffset, position: position)
            return
        }

        let point = position.pointWithOffset
        try validateFloorLevel(floorId: position.floorLevelId) { [weak self] (isValid) in
            guard let self = self else { return }
            prepareAccuracyUpload(position: position, isFloorSwap: !isValid)
            if let startLocationAngle = startWithAngle(startPosition: position.point) {
                vpsPosition.syncPosition(positions: [point], syncPosition: !position.isDisabled, syncAngle: true, angle: startLocationAngle, uncertainAngle: false)
            } else if certainAngle {
                try syncPosition(position: position, syncRotation: false, forceSync: true)
            } else {
                let syncingWithCompass = forceSync ? forceSync : doCompassStart(point: position.point) && !hasStartLocationAngle
                vpsPosition.syncPosition(positions: [point], syncPosition: !position.isDisabled, syncAngle: syncingWithCompass, angle: heading.degrees, uncertainAngle: syncingWithCompass)
            }
        }
    }

    public func syncPosition(identifier: String, type: SyncTypeEnum, reportScanEvent: Bool = true, returnOn queue: DispatchQueue = .main, completion: @escaping (Result<Item,Error>) -> ()) {
        if let code = checkForScanLocation(identifier: identifier) {
            do {
                try start(code: code)
                let item = Item(name: code.code, externalId: "", itemPositions: [ItemPosition(point: code.point, offset: .zero, floorLevelId: activeFloor.id)])
                completion(.success(item))
            } catch {
                completion(.failure(error))
            }
            return
        }
        if let syncRotation = type.get().normal, syncRotation {
            prepareAngle()
        }
        if reportScanEvent {
            createAnalyticsScanEventForIdentifier(identfier: identifier)
        }
        func doSync(position: ItemPosition) throws {
            switch type {
            case .compass(let forceSync):
              try syncPosition(position: position, forceSync: forceSync)
            case .normal(let syncRotation):
              try syncPosition(position: position, syncRotation: syncRotation, forceSync: true)
            }
        }
        positionManager.getBy(shelfName: identifier) { (position) in
          if let position = position {
            do {
              try doSync(position: position)
              let item = Item(name: "", externalId: position.identifier, itemPositions: [position])
              queue.async { completion(.success(item)) }
            } catch {
              queue.async { completion(.failure(error)) }
            }
          } else {
            self.positionManager.getBy(barcode: identifier) { (result) in
              switch result {
              case .success(let item):
                do {
                  if item.uniquePositions.isEmpty {
                    self.prepareAccuracyUpload(identifier: identifier)
                    throw NSError(domain: "No unique positions", code: 400)
                  } else if item.uniquePositions.count > 1 {
                    self.prepareAccuracyUpload(item: item)
                    throw NSError(domain: "Unique positions more than 1", code: 400)
                  } else if let position = item.itemPosition {
                    try doSync(position: position)
                    queue.async { completion(.success(item)) }
                  } else {
                    throw NSError(domain: "Case not handled", code: 400)
                  }
                } catch {
                  queue.async { completion(.failure(error)) }
                }
              case .failure(let error): completion(.failure(error))
              }
            }
          }
        }
    }

    public func syncPosition(location: CLLocation) throws {
      guard isActive else {
        try start(startPosition: location.coordinate.asPoint, startAngle: location.course)
        return
      }
      vpsPosition.syncPosition(location: location)
    }

    public func stop() {
        vpsPosition.stop()
        hasStartLocationAngle = false
        setIsVPSRunning.invoke(isVPSRunning: false, qrStart: false)
    }

    public func prepareAngle() { vpsPosition.prepareAngle() }

  public func forceSyncPosition(position: CGPoint, angle: Double) {
    vpsPosition.forceSyncPosition(position: position, angle: angle, forceAngle: true)
  }
}

// MARK: Internal
extension Navigation {
    func setup(inAndOutZone: InAndOutZone) {
        self.inAndOutZone = inAndOutZone
        bindPublishers()
    }

    func checkForScanLocation(identifier: String) -> PositionedCode? {
      floors
        .map({ $0.scanLocations?.filter({ $0.type == .start }) })
        .compactMap({ $0 })
        .flatMap({ $0 })
        .first(where: { $0.code == identifier })
    }

    func syncAngleCorrection(angle: Double, position: CGPoint) {
      guard isActive else { return }
      vpsPosition.syncAngleCorrection(angle: angle, positions: [position])
    }

    func syncPositionToNearestAccessPoint() throws {
      try start(startPosition: currentAccessPointPosition)
    }

    func changeFloorStart(startPosition: CGPoint?) throws {
        guard let point = startPosition, isActive else { try onValidateFloorCompletion?(); return }

        try vpsPosition.start(withoutAltimeter: !isAutoFloorChangeEanbled)

        vpsPosition.startNavigation(positions: [point], syncPosition: true, syncAngle: true, angle: userStartAngle.degrees, uncertainAngle: false)
    }

    func changeFloorStop() {
        guard isActive else { return }
        vpsPosition.stop(stopSensors: false)
    }

    func startRecording() {
        vpsPosition.startRecording()
    }

    func stopRecording() {
        vpsPosition.stopRecording()
    }
}

// MARK: Private
private extension Navigation {
    func bindPublishers() {
      cancellable.removeAll()
      vpsUpdates.invoke()
        .sink { [weak self] (position) in
          guard let position = position else { return }
          self?.inAndOutZone?.onNewPosition(currentPosition: position.point)
        }.store(in: &cancellable)
    }

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

    func createAnalyticsScanEventForIdentifier(identfier: String) {
      var events = [ScanEvent]()
      if let zoneIds = inAndOutZone?.activeInside.map({ $0.id }), !zoneIds.isEmpty {
        events.append(.createZoneScanEvent(identifier: identfier, floorLevelId: activeFloor.id, userPosition: currentPosition, zones: zoneIds))
      }
      
      func addShelfScanEvent(position: ItemPosition) {
        if position.floorLevelId == activeFloor.id {
          events.append(.createShelfScanEvent(itemPosition: position, userPosition: currentPosition))
        }
      }

      func addUnknownScanEvent() {
        events.append(.createUnknownScanEvent(identfier: identfier, floorLevelId: activeFloor.id, userPosition: currentPosition))
      }

      let group = DispatchGroup()
      group.enter()
      positionManager.getBy(shelfName: identfier) { (position) in
        if let position = position {
          addShelfScanEvent(position: position)
          group.leave()
        } else {
          self.positionManager.getBy(barcode: identfier) { (result) in
            switch result {
            case .success(let item):
              if let position = item.itemPosition {
                addShelfScanEvent(position: position)
              }
            case .failure(_): 
              addUnknownScanEvent()
            }
            group.leave()
          }
        }
      }

      group.notify(queue: .main) {
        if events.isEmpty {
          addUnknownScanEvent()
        }

        self.scanEventsPublisher.send(events)
      }
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
