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
  @OptionalInject var modelManager: VSMLModelManager?

  @Inject var vpsUpdates: SubscribeToVPSUpdatesUseCase
  @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
  @Inject var setIsVPSRunning: SetIsVPSRunningUseCase
  @Inject var setIsReferenceAngleCertain: SetIsReferenceAngleCertainUseCase
  @Inject var resetBuffer: ResetAnalyticsBufferUseCase
  @Inject var resetStatusRepository: ResetStatusRepositoryUseCase

  var activeFloor: RtlsOptions? {
    @Inject var activeFloor: GetActiveFloorUseCase
    return try? activeFloor.invoke()
  }

  var floors: [RtlsOptions] {
    @Inject var getFloors: GetCachedFloorsUseCase
    return getFloors.invoke()
  }

  var isAutoFloorChangeEanbled: Bool {
    getTT2Settings.invoke().isAutomaticFloorChangeEnabled
  }

  @Inject var getPosition: GetCurrentVPSPositionUseCase
  @Inject var vpsPositionPublisher: SubscribeToVPSUpdatesUseCase
  var onForceSyncPublisher: CurrentValueSubject<Void?, Never> = .init(nil)

  var accuracyPublisher: CurrentValueSubject<(event: AccuracySyncEvent.Event, isFloorSwap: Bool)?,Never> = .init(nil)
  var scanEventsPublisher: CurrentValueSubject<[ScanEvent]?, Never> = .init(nil)

  var currentAccessPointPosition: CGPoint = .zero
  var inAndOutZone: InAndOutZone?

  private let tag = "Navigation"
  private var startCodes: [PositionedCode] { activeFloor?.scanLocations?.filter({ $0.type == .start }) ?? [] }
  private var hasStartLocationAngle: Bool = false
  private var certainAngle: Bool = false
  private var cancellables = Set<AnyCancellable>()

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
    if activeFloor?.id == floorId {
      try completion(true)
    } else {
      guard let rtls = floors.first(where: { $0.id == floorId }) else { return }
      onValidateFloorCompletion = { try completion(false); self.onValidateFloorCompletion = nil }
      floorManager.switchFloorPublisher.send((rtlsOptions: rtls, point: nil))
    }
  }

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }
}

// MARK: INavigation
extension Navigation: INavigation {
  public var currentPosition: CGPoint? { getPosition.invoke()?.point }

  public var positionPublisher: AnyPublisher<VPSOutputSignal.Position?, Never> { vpsPositionPublisher.invoke() }

  public func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    modelManager = nil
  }

  public var isActive: Bool {
    @Inject var isVPSRunning: GetIsVPSRunningUseCase
    return isVPSRunning.invoke()
  }
  public var compassHeading: Double? { heading?.degrees }

  public func syncPosition(
    identifier: String,
    syncAngle: Bool,
    uncertainAngle: Bool,
    withForce: Bool,
    reportScanEvent: Bool,
    returnOn queue: DispatchQueue,
  ) -> AnyPublisher<Item,Error> {
    if uncertainAngle {
      return syncPosition(identifier: identifier, type: .compass(forceSync: withForce), reportScanEvent: reportScanEvent, returnOn: queue)
    } else if syncAngle || !uncertainAngle {
      return syncPosition(identifier: identifier, type: .normal(syncRotation: syncAngle), reportScanEvent: reportScanEvent, returnOn: queue)
    } else {
      return syncPosition(identifier: identifier, type: .compass(forceSync: false), reportScanEvent: reportScanEvent, returnOn: queue)
    }
  }

  public func syncPosition(
    identifier: String,
    syncAngle: Bool,
    uncertainAngle: Bool,
    withForce: Bool,
    reportScanEvent: Bool,
    returnOn queue: DispatchQueue,
    completion: @escaping (Result<Item,Error>) -> ()
  ) {
    syncPosition(identifier: identifier, syncAngle: syncAngle, uncertainAngle: uncertainAngle, withForce: withForce, reportScanEvent: reportScanEvent, returnOn: queue)
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  public func stop() {
    vpsPosition.stop()
    hasStartLocationAngle = false
    resetStatusRepository.invoke()
    resetBuffer.invoke()
  }

  public func prepareAngle() { vpsPosition.prepareAngle() }

  public func forceSyncPosition(position: CGPoint, angle: Double) {
    guard isActive else { return }
    vpsPosition.forceSyncPosition(position: position, angle: angle, forceAngle: true)
    setIsReferenceAngleCertain.invoke(isReferenceAngleCertain: true)
    onForceSyncPublisher.send(())
  }
}

public extension Navigation {
  /// Start Positioning System
  func start(startPosition: CGPoint, startAngle: Double) throws {
    guard modelManager?.mlModel != nil, modelManager?.mlParams != nil else { throw TT2Error.missingData }
    guard !isActive else {
      //self.stop()
      //var err: Error?
      //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      //  do {
      //    try self.start(startPosition: startPosition, startAngle: startAngle)
      //  } catch {
      //    err = error
      //  }
      //}
      //if let error = err { throw error }
      forceSyncPosition(position: startPosition, angle: startAngle)
      return
    }

    try vpsPosition.start(withoutAltimeter: !isAutoFloorChangeEanbled)
    certainAngle = true
    vpsPosition.startNavigation(positions: [startPosition], syncPosition: true, syncAngle: true, angle: startAngle, uncertainAngle: false)
    setIsReferenceAngleCertain.invoke(isReferenceAngleCertain: true)
    setIsVPSRunning.invoke(isVPSRunning: true)
    userStartAngle = TT2Course(fromDegrees: startAngle)
  }

  /// Start Positioning System with Compass angle
  func start(startPosition: CGPoint, position: ItemPosition? = nil) throws {
    guard modelManager?.mlModel != nil, modelManager?.mlParams != nil, let heading = heading else { throw TT2Error.missingData }
    guard !isActive else {
      //self.stop()
      //var err: Error?
      //DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      //  do {
      //    try self.start(startPosition: startPosition, position: position)
      //  } catch {
      //    err = error
      //  }
      //}
      //if let error = err { throw error }
      forceSyncPosition(position: startPosition, angle: heading.degrees)
      return
    }

    let startWithAngle = startWithAngle(startPosition: startPosition)
    try validateFloorLevel(floorId: position?.floorLevelId) { [weak self] (isValid) in
      guard let self = self else { return }
      try vpsPosition.start(withoutAltimeter: !isAutoFloorChangeEanbled)
      vpsPosition.startNavigation(positions: [startPosition], syncPosition: true, syncAngle: true, angle: startWithAngle ?? heading.degrees, uncertainAngle: startWithAngle == nil)
      prepareAccuracyUpload(position: position, startDirection: heading.degrees, isFloorSwap: !isValid)
      setIsReferenceAngleCertain.invoke(isReferenceAngleCertain: false)
      setIsVPSRunning.invoke(isVPSRunning: true)
      userStartAngle = heading
    }
  }

  func syncPosition(position: ItemPosition, syncRotation: Bool, forceSync: Bool) throws {
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

  func syncPosition(position: ItemPosition, forceSync: Bool = false) throws  {
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

  func syncPosition(location: CLLocation) throws {
    guard isActive else {
      try start(startPosition: location.coordinate.asPoint, startAngle: location.course)
      return
    }
    vpsPosition.syncPosition(location: location)
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
    vpsPosition.stop(shouldStopSensors: false)
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
    cancellables.removeAll()
    vpsUpdates.invoke()
      .sink { [weak self] (position) in
        guard let position = position else { return }
        self?.inAndOutZone?.onNewPosition(currentPosition: position.point)
      }.store(in: &cancellables)
  }

  func start(code: PositionedCode) throws {
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

  func syncPosition(identifier: String, type: SyncTypeEnum, reportScanEvent: Bool, returnOn queue: DispatchQueue) -> AnyPublisher<Item, Error> {
    func performSync(_ position: ItemPosition) throws {
      switch type {
      case .compass(let forceSync):
        try syncPosition(position: position, forceSync: forceSync)
      case .normal(let syncRotation):
        try syncPosition(position: position, syncRotation: syncRotation, forceSync: true)
      }
    }

    func requireSinglePosition(in item: Item) throws -> ItemPosition {
      if item.uniquePositions.isEmpty {
        prepareAccuracyUpload(identifier: identifier)
        throw NSError(domain: "No unique positions", code: 400)
      }
      if item.uniquePositions.count > 1 {
        prepareAccuracyUpload(item: item)
        throw NSError(domain: "Unique positions more than 1", code: 400)
      }
      if let position = item.itemPosition {
        return position
      }
      throw NSError(domain: "Case not handled", code: 400)
    }

    return Deferred { [weak self] () -> AnyPublisher<Item, Error> in
      guard let self else { return .fail(with: TT2Error.missingData) }

      // Nothing happens until subscription now 👌
      if let code = checkForScanLocation(identifier: identifier) {
        return .justOrFail {
          try self.start(code: code)
          return Item(name: code.code, externalId: "", itemPositions: [.init(point: code.point, offset: .zero, floorLevelId: self.activeFloor?.id)])
        }
      }

      if let syncRotation = type.get().normal, syncRotation {
        prepareAngle()
      }

      if reportScanEvent {
        createAnalyticsScanEventForIdentifier(identifier: identifier)
      }

      return positionManager.getBy(identifier: identifier)
        .tryMap { (item) in
          let position = try requireSinglePosition(in: item)
          try performSync(position)
          return item
        }
        .eraseToAnyPublisher()
    }
    .receive(on: queue)
    .eraseToAnyPublisher()
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

  func createAnalyticsScanEventForIdentifier(identifier: String) {
    guard let floorId = activeFloor?.id else { return }

    var baseEvents = [ScanEvent]()
    if let zoneIds = inAndOutZone?.activeInside.map({ $0.id }), !zoneIds.isEmpty {
      baseEvents.append(.createZoneScanEvent(identifier: identifier, floorLevelId: floorId, userPosition: currentPosition, zones: zoneIds))
    }

    positionManager.getBy(identifier: identifier)
      .map { [weak self] item -> [ScanEvent] in
        guard let self = self else { return baseEvents }
        var events = baseEvents
        if let position = item.itemPosition, position.floorLevelId == floorId {
          events.append(.createShelfScanEvent(itemPosition: position, userPosition: currentPosition))
        }
        return events
      }
      .catch { _ in Just(baseEvents) }
      .map { [weak self] in
        guard let self = self, $0.isEmpty || $0.allSatisfy({ $0.type == .zone }) else { return $0 }
        return $0 + [.createUnknownScanEvent(identfier: identifier, floorLevelId: floorId, userPosition: currentPosition)]
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.scanEventsPublisher.send($0) }
      .store(in: &cancellables)
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
