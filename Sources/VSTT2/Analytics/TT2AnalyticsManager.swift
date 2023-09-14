//
// TT2AnalyticsManager
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import Combine
import CoreGraphics
import UIKit
import  VSPositionKit

final public class TT2AnalyticsManager: TT2Analytics {
    @Inject var createVisitService: CreateVisitService
    @Inject var stopVisitService: StopVisitService
    @Inject var tagsVisitService: TagsVisitService
    @Inject var uploadPositionsService: UploadPositionsService
    @Inject var uploadTriggersService: UploadTriggersService
    @Inject var uploadScanEventsService: UploadScanEventsService
    @Inject var positionUploadWorker: PositionUploadWorker
    @Inject var zoneManager: TT2ZoneManager
    @Inject var eventManager: TT2EventManager
    @Inject var mlModelManager: VSMLModelManager
    @Inject var navigationManager: Navigation

    var accuracyUploader: AccuracyUploader?
    var stepEventUploader: StepEventUploader?
    var tt2Tags: [String:String] = [:]
    private var store: Store?
    private var uploadThreshold = 0
    var visitId: Int64?
    var rtlsOptionId: Int64?
    private var cancellable = Set<AnyCancellable>()
    private var isRecording: Bool = false
    private var latestRecordedPosition = Date()
    /// now we are uploading positions each time when they are 100
    private var recordedPositionsCount = 0

    public init() {}

    func setup(with store: Store, rtlsOptionId: Int64?, uploadThreshold: Int = 100) {
        self.store = store
        self.uploadThreshold = uploadThreshold
        self.rtlsOptionId = rtlsOptionId
        self.stepEventUploader = StepEventUploader()
        bindPublishers()
    }

    public func startVisit(deviceInformation: DeviceInformation, tags: [String:String] = [:], metaData: [String:String] = [:], completion: @escaping (Result<Int64, Error>) -> Void) {
        guard
            let storeId = store?.statServerConnection.storeId,
            visitId == nil
        else { completion(.failure(TT2AnalyticsError.visitAlreadyStarted)); return }

        var editedTags = tags
        tt2VisitStartTags.forEach { editedTags[$0.key] = $0.value }
        (tt2VPSSettingsTags ?? tt2VPSSettingsDefaultTags).forEach { editedTags[$0.key] = $0.value }
        tt2Tags = editedTags.filter { $0.key.lowercased().contains("tt2") }

        let date = DateFormatter.standardFormatter.string(from: Date())
        let parameters = CreateVisitParameters(
            requestId: UUID().uuidString.uppercased(),
            storeId: storeId,
            start: date,
            stop: date,
            deviceInformation: deviceInformation,
            tags: editedTags,
            metaData: metaData
        )
        createVisitService
            .call(with: parameters)
            .sink(receiveCompletion: { (subscriberCompletion) in
                switch subscriberCompletion {
                case .finished: break
                case .failure(let error):
                    Logger(verbosity: .debug).log(message: error.localizedDescription)
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }, receiveValue: { [weak self] (data) in
                self?.visitId = data.visitId
                DispatchQueue.main.async { completion(.success(data.visitId)) }
            }).store(in: &cancellable)
    }

    public func startCollectingHeatMapData() throws {
        guard visitId != nil else { throw TT2AnalyticsError.visitNotStarted }
        isRecording = true
    }

    public func stopCollectingHeatMapData() {
        isRecording = false
    }

    public func stopVisit() {
        guard let visitId = visitId else { return }
        positionUploadWorker.getPoints().forEach { (key, value) in
          uploadData(visitId: key, recordedPositions: value)
        }
        stepEventUploader?.upload()
        if let point = currentPosition {
            zoneManager.stopped(currentPosition: point)
            currentPosition = nil
        }
        if let event = mlPositionsToTriggerEvent() {
          addTriggerEvent(for: event)
        }
        let parameters = StopVisitParameters(
          requestId: UUID().uuidString.uppercased(),
          visitId: visitId,
          stopTimestamp: DateFormatter.standardFormatter.string(from: Date())
        )
        stopVisitService
            .call(with: parameters)
            .sink { [weak self] (result) in
                switch result {
                case .finished: self?.positionUploadWorker.removeAllPoints()
                case .failure(let error): Logger(verbosity: .debug).log(message: "StopVisitError: \(error.localizedDescription)")
                }
            } receiveValue: { (_) in
                self.recordedPositionsCount = 0
                self.visitId = nil
            }.store(in: &cancellable)
    }

    var recordedMLPositions: [Int64: [RecordedPosition]] = [:]
    func addMLPositions(id: Int64, position: VPSOutputSignal.Position) {
      let position = RecordedPosition(xPosition: position.position.x, yPosition: position.position.y, timestamp: DateFormatter.standardFormatter.string(from: position.timestamp))
      if recordedMLPositions[id] == nil { recordedMLPositions[id] = [] }
      recordedMLPositions[id]?.append(position)
    }

    struct MLPositionRecording: Codable {
      let positions: [RecordedPosition]
    }

    func mlPositionsToTriggerEvent() -> TriggerEvent? {
      defer { recordedMLPositions.removeAll() }
      guard
        let id = rtlsOptionId,
        let json = try? JSONEncoder().encode(recordedMLPositions.flatMap({ $0.value })),
        let string = String(data: json, encoding: .utf8)
      else { return nil }
      return TriggerEvent(id: "", rtlsOptionsId: id, name: "MLPositions", description: "", eventType: .appTrigger(TriggerEvent.AppTrigger(event: "MLPositionsTrigger")), tags: ["mlPositions" : string])
    }

    func update(rtlsOptionId: Int64) {
        self.rtlsOptionId = rtlsOptionId
    }

    var currentPosition: CGPoint?
    internal func onNewPositionBundle(position: VPSOutputSignal.Position) {
        guard Date().timeIntervalSince(latestRecordedPosition) > 0.2 else { return }
        self.latestRecordedPosition = Date()
        currentPosition = position.position
        if let id = rtlsOptionId, isRecording {
            recordPosition(rtlsOptionId: id, position: position)
            zoneManager.onNewPosition(currentPosition: position.position)
            eventManager.onNewPosition(currentPosition: position.position)
        }
    }
    
    public func addTriggerEvent(for event: TriggerEvent) {
        let event = postTriggerEvent(for: event)
        uploadTriggerEvents(request: event)
    }

    public func postScanEvents(position: ItemPosition) {
        guard let visitId = visitId else { return }
        
        let parameters = UploadScanEventsParameters(visitId: visitId, requestId: UUID().uuidString.uppercased(), barcode: position.identifier, shelfId: position.shelfId ?? -1, point: position.point, timeStamp: DateFormatter.standardFormatter.string(from: Date()), type: .unknown)

        uploadScanEventsService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished: break
                case .failure(let error): Logger(verbosity: .warning).log(message: error.localizedDescription)
                }
            }, receiveValue: { (_) in
                /// No data returned
            }).store(in: &cancellable)
    }
    
    private func bindPublishers() {
       zoneManager.zoneEnteredPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneEnteredPublisher error")
            } receiveValue: { [weak self] (data) in
                guard let event = self?.postTriggerEvent(for: data) else { return }
                
                self?.uploadTriggerEvents(request: event)
            }
            .store(in: &cancellable)
        
         zoneManager.zoneExitedPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneExitedPublisher error")
            } receiveValue: { [weak self] (data) in
                guard let event = self?.postTriggerEvent(for: data) else { return }
                
                self?.uploadTriggerEvents(request: event)
            }
            .store(in: &cancellable)
    }

    func updateVisitWithMLTags(mlUser: MlUser) {
      guard let visitId = visitId else { return }
      let hasML = !mlUser.speedModifier.isEmpty || !mlUser.directionModifier.isEmpty
      let tags = [
        "tt2MLActive": hasML ? "true" : "false",
        "tt2MLAlgorithm": mlUser.mlAlgorithm.rawValue,
        "tt2MLSpeedModifier": mlUser.speedModifier.description,
        "tt2MLDirectionModifier": mlUser.directionModifier.description
      ]
      let parameters = TagsVisitParameters(requestId: UUID().uuidString.uppercased(), visitId: visitId, tags: tags)
      tagsVisitService
        .call(with: parameters)
        .sink { (result) in
          switch result {
          case .finished: break
          case .failure(let error): Logger(verbosity: .debug).log(message: "UpdateVisitWithMLTagsError \(error)")
          }
        } receiveValue: { (_) in

        }
        .store(in: &cancellable)
    }
    
    private func postTriggerEvent(for event: TriggerEvent) -> PostTriggerEventRequest {
        let eventType = event.eventType.getTrigger()
        let timestamp = DateFormatter.standardFormatter.string(from: event.timestamp)
        return  PostTriggerEventRequest(
            rtlsOptionsId: String(event.rtlsOptionsId),
            name: event.name,
            timeStamp: timestamp,
            userPosition: event.userPosition,
            appTrigger: eventType.appTrigger?.asPostTrigger,
            coordinateTrigger: eventType.coordinateTrigger?.asPostTrigger,
            shelfTrigger: eventType.shelfTrigger?.asPostTrigger,
            zoneTrigger: eventType.zoneTrigger?.asPostTrigger,
            tags: event.tags,
            metaData: event.metaData
        )
    }
    
    deinit {
        cancellable.removeAll()
    }
}

private extension TT2AnalyticsManager {
    // MARK: Heatmap data
    func recordPosition(rtlsOptionId: Int64, position: VPSOutputSignal.Position) {
        recordedPositionsCount += 1
        let time = DateFormatter.standardFormatter.string(from: position.timestamp)
        if let id = visitId {
            positionUploadWorker.insert(id: String(rtlsOptionId), xPosition: Double(position.position.x), yPosition: Double(position.position.y), time: time, uploadStatus: .pending, visitId: id)
        }
        if self.checkIfPartialUpload() {
            positionUploadWorker.getPoints().forEach { (key, value) in
                self.uploadData(visitId: key, recordedPositions: value)
            }
            self.recordedPositionsCount = 0
        }
    }

    private func checkIfPartialUpload() -> Bool {
        return recordedPositionsCount > self.uploadThreshold
    }
    
    ///Uploading Heatmap data
    private func uploadData(visitId: Int64, recordedPositions: [String: [RecordedPosition]]) {
        let parameters = UploadPositionsParameters(visitId: visitId, requestId: UUID().uuidString.uppercased(), positionGrps: recordedPositions)
        uploadPositionsService
            .call(with: parameters)
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .finished:
                    self?.positionUploadWorker.removePoints()
                case .failure(let error):
                    self?.positionUploadWorker.updatePointsAfter(uploadingFailed: true)
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] (_) in
                Logger.init(verbosity: .debug).log(message: "Recorded Positions Uploaded")
                self?.positionUploadWorker.updatePointsAfter(uploadingFailed: false)
            }).store(in: &cancellable)
    }

    // MARK: Trigger Events
    private func uploadTriggerEvents(request: PostTriggerEventRequest) {
        guard let visitId = visitId else { return }

        let parameters = UploadTriggersParameters(visitId: visitId, requestId: UUID().uuidString.uppercased(), request: request)

        uploadTriggersService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { (_) in
                Logger(verbosity: .debug).log(message: "\(request.name), uploadTriggerEvents success")
            }).store(in: &cancellable)
    }

    func getVPSParams() -> String {
      var string = "{"
      navigationManager
        .positionKitManager
        .vpsParams
        .sorted(by: {
          guard let key1 = Int($0.key), let key2 = Int($1.key) else { return $0.key < $1.key }
          return key1 < key2
        })
        .forEach { string = string + "\($0.key)=\($0.value), " }
      if string.hasSuffix(", ") { string.removeLast(2) }
      string = string + "}"
      return string
    }
}

private extension TT2AnalyticsManager {
  var tt2VisitStartTags: [String:String] {
    [
      "tt2SdkVersion" : version,
      "tt2VpsVersion" : vpsVersion,
      "tt2DeviceManufacturer" : "Apple",
      "tt2DeviceModel" : UIDevice.current.modelName,
      "tt2DeviceOs" : UIDevice.current.systemName,
      "tt2DeviceOsVersion" : UIDevice.current.systemVersion,
      "tt2MLActive" : "false",
      "tt2VelocityModelName": mlModelManager.currentVersion?.name ?? "",
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
    guard let settings = store?.positionServiceSettings else { return nil }
    return [
      "tt2SdkVpsSettingUseML" : settings.useML.description,
      "tt2SdkVpsSettingUseCoefficientOptimizer" : settings.useCoefficientOptimizer.description,
      "tt2SdkVpsSettingUseDriftCompensator" : settings.useDriftCompensator.description
    ]
  }
}
