//
// TT2AnalyticsManager
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import Combine
import CoreLocation
import UIKit
import VSPositionKit

final public class TT2AnalyticsManager: Disposable {
  @Inject var positionUploadWorker: PositionUploadWorker
  @Inject var zoneManager: TT2ZoneManager
  @Inject var eventManager: TT2EventManager
  @Inject var navigationManager: Navigation

  @Inject var activeFloor: GetActiveFloorUseCase
  @Inject var activeStore: GetActiveStoreUseCase
  @Inject var activeVisitId: GetActiveVisitIDUseCase
  @Inject var createVisit: CreateVisitUseCase
  @Inject var endVisit: StopVisitUseCase
  @Inject var getCurrentPosition: GetCurrentVPSPositionUseCase
  @Inject var getCurrentLeaseExpired: GetCurrentLeaseExpiredUseCase
  @Inject var getCurrentLeasePolicy: GetCurrentLeasePolicyUseCase
  @Inject var getScanEvents: GetScanEventsUseCase
  @Inject var getSyncEvents: GetSyncEventsUseCase
  @Inject var getTriggerEvents: GetTriggerEventsUseCase
  @Inject var getMLVersion: GetMLVersionUseCase
  @Inject var getNLVersion: GetNLVersionUseCase
  @Inject var getNPVersion: GetNPVersionUseCase
  @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
  @Inject var updateTags: UpdateTagsForActiveVisitUseCase
  @Inject var uploadGeopositions: UploadGeopositionsForActiveVisitUseCase
  @Inject var uploadPositions: UploadPositionsForVisitUseCase
  @Inject var upload: AnalyticsUploadUseCase
  @Inject var uploadZoneSummary: UploadZoneSummaryForActiveVisitUseCase
  @Inject var bufferOrPersist: BufferOrPersistEventForActiveVisitUseCase

  lazy var accuracyUploader: AccuracyUploader? = { .init() }()
  lazy var stepEventUploader: StepEventUploader? = { .init() }()
  lazy var visitScoreManager: TT2AnalyticsScoreManager = { .init() }()
  let geopositionsManager: TT2AnalyticsGeopositionManager = .init()
  let wayfindingBusiness: WayfindingAnalyticsBusiness = .init()
  var tt2Tags: [String:String] = [:]
  var leaseExpired: Bool { getCurrentLeaseExpired.invoke() }
  var visitId: Int64? { activeVisitId.invoke() }
  private let tag = "TT2AnalyticsManager"
  private var store: Store? { try? activeStore.invoke() }
  private var uploadThreshold = 100
  private var rtlsOptionId: Int64? { try? activeFloor.invoke().id }
  private var cancellables = Set<AnyCancellable>()
  private var isRecording: Bool = false
  private var latestRecordedPosition = Date()
  /// now we are uploading positions each time when they are 100
  private var recordedPositionsCount = 0
  var recordedMLPositions: [Int64: [RecordedPosition]] = [:]
  var recordedMLPositionsLngLat: [Int64: [RecordedPositionLngLat]] = [:]
  private var currentPosition: CGPoint? { getCurrentPosition.invoke()?.point }
  private var zoneSummaryBusiness = AnalyticsZoneSummaryBusiness()
  private let serialDispatch = DispatchQueue(label: "TT2ANALYTICSMANAGERSERIAL")

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }

  public func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    accuracyUploader = nil
    stepEventUploader = nil
    zoneManager.dispose()
    cancellables.removeAll()
  }

  public func stopTrackingWayfinding(identifier: String) {
    serialDispatch.async { [weak self] in
      guard
        let self = self,
        let event = wayfindingBusiness.stopTracking(identifier: identifier)
      else { return }
      addTriggerEvent(for: event)
    }
  }
}

private extension TT2AnalyticsManager {
  var tt2VisitStartTags: [String:String] {
    [
      "tt2SdkVersion" : TT2.version,
      "tt2VpsVersion" : vpsVersion,
      "tt2DeviceManufacturer" : "Apple",
      "tt2DeviceModel" : UIDevice.current.modelName,
      "tt2DeviceOs" : UIDevice.current.systemName,
      "tt2DeviceOsVersion" : UIDevice.current.systemVersion,
      "tt2MLActive" : "false",
      "tt2VelocityModelName": getMLVersion.invoke()?.name ?? "",
      "tt2NLModelName": getNLVersion.invoke()?.name ?? "",
      "tt2NPModelName": getNPVersion.invoke()?.name ?? "",
      "tt2SdkVpsSettings": getVPSParams(),
      "tt2VpsEngine": getTT2Settings.invoke().engine.rawValue,
      "tt2BatteryLevelAtStart": (UIDevice.current.batteryLevel * 100).description
    ]
  }

  var tt2VPSSettingsDefaultTags: [String:String] {
    [
      "tt2SdkVpsSettingUseML" : "true",
      "tt2SdkVpsSettingUseCoefficientOptimizer" : "true",
      "tt2SdkVpsSettingUseDriftCompensator" : "false"
    ]
  }

  var tt2VPSSettingsTags: [String:String]? {
    guard let settings = store?.positionServiceSettings else { return nil }
    return [
      "tt2SdkVpsSettingUseML" : settings.useML.description,
      "tt2SdkVpsSettingUseCoefficientOptimizer" : settings.useCoefficientOptimizer.description,
      "tt2SdkVpsSettingUseDriftCompensator" : settings.useDriftCompensator.description
    ]
  }

  func bindPublishers() {
    zoneManager.zoneEnteredPublisher
      .compactMap { $0 }
      .sink { [weak self] (data) in
        self?.zoneSummaryBusiness.onEnter(event: data)
      }
      .store(in: &cancellables)

    zoneManager.zoneExitedPublisher
      .compactMap { $0 }
      .sink { [weak self] (data) in
        self?.zoneSummaryBusiness.onExit(event: data)
      }
      .store(in: &cancellables)

    eventManager.messageShownPublisher
      .compactMap { $0 }
      .sink { [weak self] (event) in
        self?.addTriggerEvent(for: event)
      }.store(in: &cancellables)
  }

  func postTriggerEvent(for event: TriggerEvent) -> PostTriggerEventRequest {
    event
      .checkForZoneTrigger()
      .asRequest(userPosition: currentPosition ?? .zero)
  }

  // MARK: Heatmap data
  func recordPosition(rtlsOptionId: Int64, position: VPSOutputSignal.Position) {
    recordedPositionsCount += 1
    if let id = visitId {
      positionUploadWorker.insert(
        floorId: rtlsOptionId,
        position: RecordedPosition(
          xPosition: position.point.x,
          yPosition: position.point.y,
          timestamp: DateFormatter.standardFormatter.string(from: position.timestamp)
        ),
        visitId: id
      )
    }
    if checkIfPartialUpload() {
      recordedPositionsCount = 0
      uploadPositionData()
      postMLPositionsAsTriggerEvent()
      uploadZoneSummaryEvents()
      uploadAllInDatabase()
    }
  }

  func checkIfPartialUpload() -> Bool {
    recordedPositionsCount > uploadThreshold
  }

  ///Uploading Heatmap data
  func uploadPositionData() {
    positionUploadWorker.getParameters().forEach { (parameters) in
      uploadPositions.invoke(parameters: parameters) { [weak self] (error) in
        if let error = error {
          self?.positionUploadWorker.updateObjectsAfterUpload(didFail: true)
          Logger(verbosity: .debug).log(message: error.localizedDescription)
        } else {
          self?.positionUploadWorker.updateObjectsAfterUpload(didFail: false)
          self?.positionUploadWorker.removeAllPoints()
          self?.positionUploadWorker.removeCompletedObjects()
          Logger(verbosity: .debug).log(message: "Recorded Positions Uploaded")
        }
      }
    }
  }

  // MARK: Trigger Events
  func uploadAllInDatabase() {
    getScanEvents.invoke().forEach { upload.invoke($0) }
    getSyncEvents.invoke().forEach { upload.invoke($0) }
    getTriggerEvents.invoke().forEach { upload.invoke($0) }
  }

  func uploadZoneSummaryEvents() {
    guard let summary = zoneSummaryBusiness.popCurrentZoneSummary() else { return }
    uploadZoneSummary.invoke(summary: summary) { (error) in
      if let error = error {
        Logger(verbosity: .debug).log(message: "UploadZoneSummary Error: \(error.localizedDescription)")
      } else {
        Logger(verbosity: .debug).log(message: "UploadZoneSummary Success")
      }
    }
  }

  func getVPSParams() -> String {
    var string = "{"
    navigationManager
      .vpsPosition
      .vpsParticleFilterSettings
      .forEach { string = string + "\($0.key)=\($0.value), " }
    if string.hasSuffix(", ") { string.removeLast(2) }
    string = string + "}"
    return string
  }

  func postMLPositionsAsTriggerEvent() {
    if let event = mlPositionsToTriggerEvent() {
      addTriggerEvent(for: event)
    }
    if let event = mlPositionsLngLatToTriggerEvent() {
      addTriggerEvent(for: event)
    }
  }

  func mlPositionsToTriggerEvent() -> TriggerEvent? {
    defer { recordedMLPositions.removeAll() }
    guard
      let id = rtlsOptionId,
      recordedMLPositions.count > 0,
      let json = try? JSONEncoder().encode(recordedMLPositions.flatMap({ $0.value })),
      let string = String(data: json, encoding: .utf8)
    else { return nil }
    return TriggerEvent(id: "", rtlsOptionsId: id, name: "MLPositions", description: "", eventType: .appTrigger(TriggerEvent.AppTrigger(event: "MLPositionsTrigger")), tags: ["mlPositions" : string])
  }

  func mlPositionsLngLatToTriggerEvent() -> TriggerEvent? {
    defer { recordedMLPositionsLngLat.removeAll() }
    guard
      let id = rtlsOptionId,
      recordedMLPositionsLngLat.count > 0,
      let json = try? JSONEncoder().encode(recordedMLPositionsLngLat.flatMap({ $0.value })),
      let string = String(data: json, encoding: .utf8)
    else { return nil }
    return TriggerEvent(id: "", rtlsOptionsId: id, name: "MLPositionsLngLat", description: "", eventType: .appTrigger(TriggerEvent.AppTrigger(event: "MLPositionsLatLngTrigger")), tags: ["mlPositionsLatLng" : string])
  }

  func updateVisitWithStopTags() {
    let tags = [
      "tt2BatteryLevelAtEnd": (UIDevice.current.batteryLevel * 100).description,
      "tt2LeaseExpired": leaseExpired.description,
      "tt2LeasePolicy": getCurrentLeasePolicy.invoke()?.rawValue ?? "None"
    ]
    updateTags.invoke(tags: tags) { (error) in
      if let error = error {
        Logger(verbosity: .debug).log(message: "UpdateVisitWithStopTagsError \(error)")
      }
    }
  }

  func invokeEndVisit() {
    serialDispatch.async { [weak self] in
      self?.endVisit.invoke { (error) in
        if let error = error {
          Logger(verbosity: .debug).log(message: "StopVisitError: \(error.localizedDescription)")
        } else {
          self?.positionUploadWorker.removeAllPoints()
          self?.recordedPositionsCount = 0
          self?.navigationManager.vpsPosition.set(sessionId: nil)
        }
      }
    }
  }
}

extension TT2AnalyticsManager {
  func setup(uploadThreshold: Int = 100) {
    self.uploadThreshold = uploadThreshold
    bindPublishers()
  }

  func addMLPositions(position: VPSOutputSignal.Position) {
    serialDispatch.async { [weak self] in
      self?.wayfindingBusiness.onNew(mlPosition: position)
      guard let self = self, let id = visitId else { return }
      if recordedMLPositions[id] == nil { recordedMLPositions[id] = [] }
      recordedMLPositions[id]?.append(RecordedPosition(
        xPosition: position.point.x,
        yPosition: position.point.y,
        timestamp: DateFormatter.standardFormatter.string(from: position.timestamp)
      ))
    }
  }

  func addMLPositions(coordinate: CLLocationCoordinate2D, date: Date = Date()) {
    serialDispatch.async { [weak self] in
      guard let self = self, let id = visitId else { return }
      if recordedMLPositionsLngLat[id] == nil { recordedMLPositionsLngLat[id] = [] }
      recordedMLPositionsLngLat[id]?.append(RecordedPositionLngLat(
        airPressure: navigationManager.vpsPosition.altimeterPublisher.value?.cmAltitude.pressure.doubleValue,
        timestamp: DateFormatter.standardFormatter.string(from: date),
        lngLat: [coordinate.longitude, coordinate.latitude]
      ))
    }
  }

  func onNewPositionBundle(position: VPSOutputSignal.Position) {
    serialDispatch.async { [weak self] in
      guard
        let self = self,
        let id = rtlsOptionId,
        Date().timeIntervalSince(latestRecordedPosition) > 0.2
      else { return }
      latestRecordedPosition = Date()
      if isRecording {
        recordPosition(rtlsOptionId: id, position: position)
        zoneManager.onNewPosition(currentPosition: position.point)
        eventManager.on(new: position)
        wayfindingBusiness.onNew(position: position)
      }
    }
  }

  func updateVisitWithMLTags(mlUser: MlUser) {
    let hasML = !mlUser.speedModifier.isEmpty || !mlUser.directionModifier.isEmpty
    let tags = [
      "tt2MLActive": hasML ? "true" : "false",
      "tt2MLAlgorithm": mlUser.mlAlgorithm.rawValue,
      "tt2MLSpeedModifier": mlUser.speedModifier.description,
      "tt2MLDirectionModifier": mlUser.directionModifier.description
    ]
    updateTags.invoke(tags: tags) { (error) in
      if let error = error {
        Logger(verbosity: .debug).log(message: "UpdateVisitWithMLTagsError \(error)")
      }
    }
  }

  func rescueMode() {
    guard let id = rtlsOptionId else { return }
    accuracyUploader?.numberOfRescueModes += 1
    addTriggerEvent(for: .init(rtlsOptionsId: id, name: "RescueModeTriggerEvent", description: "", eventType: .appTrigger(.init(event: "RescueModeTriggerEvent")), userPosition: currentPosition))
  }

  func report(visitScore: Int) {
    visitScoreManager.report(score: visitScore)
  }
}

extension TT2AnalyticsManager: TT2Analytics {
  public var hasVisit: Bool { visitId != nil }

  public func startVisit(deviceInformation: DeviceInformation, tags: [String:String] = [:], metaData: [String:String] = [:], completion: @escaping (Result<Int64, Error>) -> Void) {
    guard getMLVersion.invoke() != nil else { completion(.failure(TT2Error.missingData)); return }
    guard visitId == nil else { completion(.failure(TT2AnalyticsError.visitAlreadyStarted)); return }

    var editedTags = tags
    tt2VisitStartTags.forEach { editedTags[$0.key] = $0.value }
    (tt2VPSSettingsTags ?? tt2VPSSettingsDefaultTags).forEach { editedTags[$0.key] = $0.value }
    tt2Tags = editedTags.filter { $0.key.lowercased().contains("tt2") }

    createVisit.invoke(deviceInformation: deviceInformation, tags: editedTags, metaData: metaData)
      .handleEvents(receiveOutput: { [weak self] (visitId) in
        self?.navigationManager.vpsPosition.set(sessionId: visitId.description)
        self?.visitScoreManager.startVisit()
      })
      .receive(on: DispatchQueue.main)
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  public func startCollectingHeatMapData() throws {
    guard visitId != nil else { throw TT2AnalyticsError.visitNotStarted }
    isRecording = true
  }

  public func stopCollectingHeatMapData() {
    isRecording = false
  }

  public func stopVisit() {
    serialDispatch.async { [weak self] in
      guard let self = self else { return }
      positionUploadWorker.saveObjects()
      uploadPositionData()
      stepEventUploader?.upload()
      geopositionsManager.stopVisit()
      if let point = currentPosition {
        zoneManager.stopped(currentPosition: point)
      }
      zoneSummaryBusiness.exitAllRemainingZones(timestamp: .init())
      uploadZoneSummaryEvents()
      uploadAllInDatabase()
      if let event = wayfindingBusiness.stopVisit() {
        addTriggerEvent(for: event)
      }
      postMLPositionsAsTriggerEvent()
      updateVisitWithStopTags()
      visitScoreManager.stopVisit()
      invokeEndVisit()
    }
  }

  public func addTriggerEvent(for event: TriggerEvent) {
    serialDispatch.async { [weak self] in
      guard let event = self?.postTriggerEvent(for: event) else { return }
      self?.bufferOrPersist.invoke(event: event)
    }
  }

  public func addGeopositions(coordinate: CLLocationCoordinate2D, for tag: String) {
    serialDispatch.async { [weak self] in
      guard
        let self = self,
        let id = rtlsOptionId
      else { return }
      geopositionsManager.record(coordinate: coordinate, for: tag)
      addTriggerEvent(for: TriggerEvent(
        id: tag,
        rtlsOptionsId: id,
        name: tag,
        description: tag,
        eventType: .coordinateTrigger(.init(point: coordinate.asPoint, radius: 0, type: .enter))
      ))
    }
  }

  public func startTrackingWayfinding(itemPosition: ItemPosition) {
    serialDispatch.async { [weak self] in
      guard
        let self = self,
        let event = wayfindingBusiness.startTracking(item: WayfindingItem(identifier: itemPosition.identifier, position: itemPosition))
      else { return }
      addTriggerEvent(for: event)
    }
  }

  public func stopTrackingWayfinding(itemPosition: ItemPosition) {
    serialDispatch.async { [weak self] in
      guard
        let self = self,
        let event = wayfindingBusiness.stopTracking(identifier: itemPosition.identifier)
      else { return }
      addTriggerEvent(for: event)
    }
  }

  public func startTrackingWayfinding(zonePosition: ZonePosition) {
    serialDispatch.async { [weak self] in
      guard
        let self = self,
        let event = wayfindingBusiness.startTracking(item: WayfindingZone(identifier: zonePosition.identifier, position: zonePosition))
      else { return }
      addTriggerEvent(for: event)
    }
  }

  public func stopTrackingWayfinding(zonePosition: ZonePosition) {
    serialDispatch.async { [weak self] in
      guard
        let self = self,
        let event = wayfindingBusiness.stopTracking(identifier: zonePosition.identifier)
      else { return }
      addTriggerEvent(for: event)
    }
  }
}
