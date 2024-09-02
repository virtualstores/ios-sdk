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

final public class TT2AnalyticsManager {
    @Inject var positionUploadWorker: PositionUploadWorker
    @Inject var zoneManager: TT2ZoneManager
    @Inject var eventManager: TT2EventManager
    @Inject var navigationManager: Navigation

    @Inject var activeFloor: GetActiveFloorUseCase
    @Inject var activeStore: GetActiveStoreUseCase
    @Inject var activeVisitId: GetActiveVisitIDUseCase
    @Inject var createVisit: CreateVisitUseCase
    @Inject var endVisit: StopVisitUseCase
    @Inject var getMLVersion: GetMLVersionUseCase
    @Inject var getNLVersion: GetNLVersionUseCase
    @Inject var updateTags: UpdateTagsForActiveVisitUseCase
    @Inject var uploadGeopositions: UploadGeopositionsForActiveVisitUseCase
    @Inject var uploadPositions: UploadPositionsForVisitUseCase
    @Inject var uploadScanEvent: UploadScanEventForActiveVisitUseCase
    @Inject var uploadTriggerEvent: UploadTriggerEventForActiveVisitUseCase

    lazy var accuracyUploader: AccuracyUploader = { .init() }()
    lazy var stepEventUploader: StepEventUploader = { .init() }()
    let geopositionsManager: TT2AnalyticsGeopositionManager = .init()
    var tt2Tags: [String:String] = [:]
    var visitId: Int64? { activeVisitId.invoke() }
    private var store: Store { activeStore.invoke() }
    private var uploadThreshold = 0
    private var rtlsOptionId: Int64 { activeFloor.invoke().id }
    private var cancellable = Set<AnyCancellable>()
    private var isRecording: Bool = false
    private var latestRecordedPosition = Date()
    /// now we are uploading positions each time when they are 100
    private var recordedPositionsCount = 0
    var recordedMLPositions: [Int64: [RecordedPosition]] = [:]
    var recordedMLPositionsLngLat: [Int64: [RecordedPositionLngLat]] = [:]
    private var currentPosition: CGPoint?

    deinit {
        cancellable.removeAll()
    }
}

private extension TT2AnalyticsManager {
    func bindPublishers() {
      zoneManager.zoneEnteredPublisher
        .compactMap { $0 }
        .sink { _ in
          Logger().log(message: "zoneEnteredPublisher error")
        } receiveValue: { [weak self] (data) in
          guard let event = self?.postTriggerEvent(for: data) else { return }
          self?.uploadTriggerEvents(request: event)
        }
        .store(in: &cancellable)

      zoneManager.zoneExitedPublisher
        .compactMap { $0 }
        .sink { _ in
          Logger().log(message: "zoneExitedPublisher error")
        } receiveValue: { [weak self] (data) in
          guard let event = self?.postTriggerEvent(for: data) else { return }
          self?.uploadTriggerEvents(request: event)
        }
        .store(in: &cancellable)

      eventManager.messageShownPublisher
        .compactMap { $0 }
        .sink { [weak self] (event) in
          self?.addTriggerEvent(for: event)
        }.store(in: &cancellable)
    }

    func postTriggerEvent(for event: TriggerEvent) -> PostTriggerEventRequest {
        let eventType = event.eventType.getTrigger()
        let timestamp = DateFormatter.standardFormatter.string(from: event.timestamp)
        if let pointId = eventType.zoneTrigger?.entryPoint?.id {
            switch eventType.zoneTrigger?.type {
            case .enter: event.add(tags: ["entryPointEnterId": pointId])
            case .exit: event.add(tags: ["entryPointExitId": pointId])
            default: break
            }
        }
        return PostTriggerEventRequest(
            rtlsOptionsId: String(event.rtlsOptionsId),
            name: event.name,
            timeStamp: timestamp,
            userPosition: event.userPosition ?? currentPosition ?? .zero,
            appTrigger: eventType.appTrigger?.asPostTrigger,
            coordinateTrigger: eventType.coordinateTrigger?.asPostTrigger,
            shelfTrigger: eventType.shelfTrigger?.asPostTrigger,
            zoneTrigger: eventType.zoneTrigger?.asPostTrigger,
            tags: event.tags,
            metaData: event.metaData
        )
    }

    // MARK: Heatmap data
    func recordPosition(rtlsOptionId: Int64, position: VPSOutputSignal.Position) {
        recordedPositionsCount += 1
        let time = DateFormatter.standardFormatter.string(from: position.timestamp)
        if let id = visitId {
            positionUploadWorker.insert(id: String(rtlsOptionId), xPosition: Double(position.position.x), yPosition: Double(position.position.y), time: time, uploadStatus: .pending, visitId: id)
        }
        if checkIfPartialUpload() {
            positionUploadWorker.getPoints().forEach { (key, value) in
                uploadData(visitId: key, recordedPositions: value)
            }
            recordedPositionsCount = 0
        }
    }

    func checkIfPartialUpload() -> Bool {
        recordedPositionsCount > uploadThreshold
    }
    
    ///Uploading Heatmap data
    func uploadData(visitId: Int64, recordedPositions: [String: [RecordedPosition]]) {
      uploadPositions.invoke(visitId: visitId, positions: recordedPositions) { [weak self] (error) in
        if let error = error {
          self?.positionUploadWorker.updatePointsAfter(uploadingFailed: true)
          Logger(verbosity: .debug).log(message: error.localizedDescription)
        } else {
          self?.positionUploadWorker.updatePointsAfter(uploadingFailed: false)
          self?.positionUploadWorker.removePoints()
          Logger(verbosity: .debug).log(message: "Recorded Positions Uploaded")
        }
      }
    }

    // MARK: Trigger Events
    func uploadTriggerEvents(request: PostTriggerEventRequest) {
      uploadTriggerEvent.invoke(request: request) { (error) in
        if let error = error {
          Logger(verbosity: .debug).log(message: error.localizedDescription)
        } else {
          Logger(verbosity: .debug).log(message: "UploadTriggerEvent Success: \(request.name)")
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
      "tt2SdkVpsSettings": getVPSParams()
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
    guard let settings = store.positionServiceSettings else { return nil }
    return [
      "tt2SdkVpsSettingUseML" : settings.useML.description,
      "tt2SdkVpsSettingUseCoefficientOptimizer" : settings.useCoefficientOptimizer.description,
      "tt2SdkVpsSettingUseDriftCompensator" : settings.useDriftCompensator.description
    ]
  }
}

extension TT2AnalyticsManager {
  func setup(uploadThreshold: Int = 100) {
    self.uploadThreshold = uploadThreshold
    bindPublishers()
  }

  func addMLPositions(id: Int64, position: VPSOutputSignal.Position) {
    let position = RecordedPosition(xPosition: position.position.x, yPosition: position.position.y, timestamp: DateFormatter.standardFormatter.string(from: position.timestamp))
    if recordedMLPositions[id] == nil { recordedMLPositions[id] = [] }
    recordedMLPositions[id]?.append(position)
  }

  func addMLPositions(id: Int64, coordinate: CLLocationCoordinate2D, date: Date = Date()) {
    let position = RecordedPositionLngLat(
      airPressure: navigationManager.vpsPosition.altimeterPublisher.value?.cmAltitude.pressure.doubleValue,
      timestamp: DateFormatter.standardFormatter.string(from: Date()),
      lngLat: [coordinate.longitude, coordinate.latitude]
    )
    if recordedMLPositionsLngLat[id] == nil { recordedMLPositionsLngLat[id] = [] }
    recordedMLPositionsLngLat[id]?.append(position)
  }

  func mlPositionsToTriggerEvent() -> TriggerEvent? {
    defer { recordedMLPositions.removeAll() }
    guard
      recordedMLPositions.count > 0,
      let json = try? JSONEncoder().encode(recordedMLPositions.flatMap({ $0.value })),
      let string = String(data: json, encoding: .utf8)
    else { return nil }
    return TriggerEvent(id: "", rtlsOptionsId: rtlsOptionId, name: "MLPositions", description: "", eventType: .appTrigger(TriggerEvent.AppTrigger(event: "MLPositionsTrigger")), tags: ["mlPositions" : string])
  }

  func mlPositionsLngLatToTriggerEvent() -> TriggerEvent? {
    defer { recordedMLPositionsLngLat.removeAll() }
    guard
      recordedMLPositionsLngLat.count > 0,
      let json = try? JSONEncoder().encode(recordedMLPositionsLngLat.flatMap({ $0.value })),
      let string = String(data: json, encoding: .utf8)
    else { return nil }
    return TriggerEvent(id: "", rtlsOptionsId: rtlsOptionId, name: "MLPositionsLngLat", description: "", eventType: .appTrigger(TriggerEvent.AppTrigger(event: "MLPositionsLatLngTrigger")), tags: ["mlPositionsLatLng" : string])
  }

  func onNewPositionBundle(position: VPSOutputSignal.Position) {
    guard Date().timeIntervalSince(latestRecordedPosition) > 0.2 else { return }
    self.latestRecordedPosition = Date()
    currentPosition = position.position
    if isRecording {
      recordPosition(rtlsOptionId: rtlsOptionId, position: position)
      zoneManager.onNewPosition(currentPosition: position.position)
      eventManager.onNewPosition(currentPosition: position.position)
    }
  }

  func postScanEvents(scanEvent: ScanEvent) {
    uploadScanEvent.invoke(event: scanEvent) { (error) in
      if let error = error {
        Logger(verbosity: .warning).log(message: error.localizedDescription)
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
    accuracyUploader.numberOfRescueModes += 1
    uploadTriggerEvents(request: postTriggerEvent(for: TriggerEvent(rtlsOptionsId: rtlsOptionId, name: "RescueModeTriggerEvent", description: "", eventType: .appTrigger(.init(event: "RescueModeTriggerEvent")), userPosition: currentPosition)))
  }
}

extension TT2AnalyticsManager: TT2Analytics {
  public func startVisit(deviceInformation: DeviceInformation, tags: [String:String] = [:], metaData: [String:String] = [:], completion: @escaping (Result<Int64, Error>) -> Void) {
    guard getMLVersion.invoke() != nil else { completion(.failure(VSTT2Error.missingData)); return }
    guard visitId == nil else { completion(.failure(TT2AnalyticsError.visitAlreadyStarted)); return }

    var editedTags = tags
    tt2VisitStartTags.forEach { editedTags[$0.key] = $0.value }
    (tt2VPSSettingsTags ?? tt2VPSSettingsDefaultTags).forEach { editedTags[$0.key] = $0.value }
    tt2Tags = editedTags.filter { $0.key.lowercased().contains("tt2") }

    createVisit.invoke(deviceInformation: deviceInformation, tags: editedTags, metaData: metaData) { [weak self] (result) in
      self?.navigationManager.vpsPosition.set(sessionId: self?.visitId?.description)
      self?.navigationManager.vpsPosition.startGPS()
      completion(result)
    }
  }

  public func startCollectingHeatMapData() throws {
    guard visitId != nil else { throw TT2AnalyticsError.visitNotStarted }
    isRecording = true
  }

  public func stopCollectingHeatMapData() {
    isRecording = false
  }

  public func stopVisit() {
    positionUploadWorker.getPoints().forEach { (key, value) in
      uploadData(visitId: key, recordedPositions: value)
    }
    stepEventUploader.upload()
    geopositionsManager.stopVisit()
    if let point = currentPosition {
      zoneManager.stopped(currentPosition: point)
      currentPosition = nil
    }
    if let event = mlPositionsToTriggerEvent() {
      addTriggerEvent(for: event)
    }
    if let event = mlPositionsLngLatToTriggerEvent() {
      addTriggerEvent(for: event)
    }
    endVisit.invoke { [weak self] (error) in
      if let error = error {
        Logger(verbosity: .debug).log(message: "StopVisitError: \(error.localizedDescription)")
      } else {
        self?.positionUploadWorker.removeAllPoints()
        self?.recordedPositionsCount = 0
        self?.navigationManager.vpsPosition.set(sessionId: nil)
      }
    }
  }

  public func addTriggerEvent(for event: TriggerEvent) {
    let event = postTriggerEvent(for: event)
    uploadTriggerEvents(request: event)
  }

  public func addGeopositions(coordinate: CLLocationCoordinate2D, for tag: String) {
    geopositionsManager.record(coordinate: coordinate, for: tag)
    addTriggerEvent(for: TriggerEvent(
      id: tag,
      rtlsOptionsId: rtlsOptionId,
      name: tag,
      description: tag,
      eventType: .coordinateTrigger(.init(point: coordinate.asPoint, radius: 0, type: .enter))
    ))
  }
}
