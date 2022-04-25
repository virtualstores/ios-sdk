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



final public class TT2AnalyticsManager: TT2Analytics {
    @Inject var createVisitService: CreateVisitService
    @Inject var stopVisitService: StopVisitService
    @Inject var uploadPositionsService: UploadPositionsService
    @Inject var uploadTriggersService: UploadTriggersService
    @Inject var uploadScanEventsService: UploadScanEventsService
    @Inject var positionUploadWorker: PositionUploadWorker
    @Inject var zoneManager: TT2ZoneManager
    @Inject var eventManager: TT2EventManager

    private var store: Store?
    private var uploadThreshold = 0
    var visitId: Int64?
    private var cancellable = Set<AnyCancellable>()
    private var isRecording: Bool = false
    private var rtlsOptionId: Int64?
    private var latestRecordedPosition = Date()
    /// now we are uploading positions each time when they are 100
    private var recordedPositionsCount = 0
    private var config: EnvironmentConfig?
    
    public init() {}

    public func setup(with store: Store, rtlsOptionId: Int64?, uploadThreshold: Int = 100, config: EnvironmentConfig?) {
        self.store = store
        self.uploadThreshold = uploadThreshold
        self.rtlsOptionId = rtlsOptionId
        self.config = config
        bindPublishers()
    }

    public func startVisit(deviceInformation: DeviceInformation, tags: [String: String] = [:], metaData: [String: String] = [:], completion: @escaping (Error?) -> Void) {
        guard let storeId = store?.statServerConnection.storeId, visitId == nil else { return }

        let date = DateFormatter.standardFormatter.string(from: Date())
        let parameters = CreateVisitParameters(requestId: UUID().uuidString.uppercased(),
                                                storeId: storeId,
                                                start: date,
                                                stop: date,
                                                deviceInformation: deviceInformation,
                                                tags: tags,
                                                metaData: metaData,
                                                config: config)
        createVisitService
            .call(with: parameters)
            .sink(receiveCompletion: { (subscriberCompletion) in
                switch subscriberCompletion {
                case .finished: break
                case .failure(let error):
                    Logger(verbosity: .debug).log(message: error.localizedDescription)
                    completion(error)
                }
            }, receiveValue: { [weak self] (data) in
                self?.visitId = data.visitId
                completion(nil)
            }).store(in: &cancellable)
    }

    public func startCollectingHeatMapData() throws {
        guard visitId != nil else {
            throw TT2AnalyticsError.visitNotStarted
        }

        self.isRecording = true
    }

    public func stopCollectingHeatMapData() {
        self.isRecording = false
    }

    public func stopVisit() {
        stopCollectingHeatMapData()
        guard let visitId = visitId, let points = positionUploadWorker.getAllPoints() else { return }
        let date = DateFormatter.standardFormatter.string(from: Date())
        let parameters = StopVisitParameters(config: config, requestId: UUID().uuidString.uppercased(), visitId: visitId, stop: date, positionGrps: points)
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

    func update(rtlsOptionId: Int64) {
        self.rtlsOptionId = rtlsOptionId
    }

    internal func onNewPositionBundle(point: CGPoint) {
        guard Date().timeIntervalSince(latestRecordedPosition) > 0.2 else { return }
        self.latestRecordedPosition = Date()

        if let id = rtlsOptionId, isRecording {
            recordPosition(rtlsOptionId: id, point: point)
            zoneManager.onNewPosition(currentPosition: point)
            eventManager.onNewPosition(currentPosition: point)
        }
    }
    
    public func addTriggerEvent(for event: TriggerEvent) {
        let event = postTriggerEvent(for: event)
        uploadTriggerEvents(request: event)
    }
    
    public func bindPublishers() {
       zoneManager.zoneEnteredPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneEnteredPublisher error")
            } receiveValue: { [weak self] data in
                guard let event = self?.postTriggerEvent(for: data) else { return }
                
                self?.uploadTriggerEvents(request: event)
            }
            .store(in: &cancellable)
        
         zoneManager.zoneExitedPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneExitedPublisher error")
            } receiveValue: { [weak self] data in
                guard let event = self?.postTriggerEvent(for: data) else { return }
                
                self?.uploadTriggerEvents(request: event)
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
    func recordPosition(rtlsOptionId: Int64, point: CGPoint) {
    
        let id = String(rtlsOptionId)

        recordedPositionsCount += 1
        let time = DateFormatter.standardFormatter.string(from: Date())
        positionUploadWorker.insert(id: id, xPosition: Double(point.x), yPosition: Double(point.y), time: time, uploadStatus: .pending)

        if self.checkIfPartialUpload() {
            do {
                guard let points = try positionUploadWorker.getPoints() else { return }

                self.uploadData(recordedPositions: points)
                self.recordedPositionsCount = 0
            } catch {
                Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                    message: "GetPoints from SQLite error")
            }
        }
    }

    private func checkIfPartialUpload() -> Bool {
        return recordedPositionsCount > self.uploadThreshold
    }
    
    ///Uploading Heatmap data, config: <#EnvironmentConfig#>
    private func uploadData(recordedPositions: [String: [RecordedPosition]]) {
        guard let visitId = visitId else { return }

        let parameters = UploadPositionsParameters(visitId: visitId, requestId: UUID().uuidString.uppercased(), positionGrps: recordedPositions, config: config)

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
        guard let visitId = visitId, let apiKey = config?.centralServerConnection.apiKey else { return }

        let parameters = UploadTriggersParameters(apiKey: apiKey, visitId: visitId, requestId: UUID().uuidString.uppercased(), request: request, config: config)

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

    private func uploadScanEvents() {
        guard let visitId = visitId, let apiKey = config?.centralServerConnection.apiKey else { return }
        // Receive all this data from app
        let parameters = UploadScanEventsParameters(apiKey: apiKey, visitId: visitId, requestId: UUID().uuidString.uppercased(), barcode: "", shelfId: 1, point: CGPoint(), timeStamp: "", type: .shelf, config: config)

        uploadScanEventsService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { (_) in
                /// use data
            }).store(in: &cancellable)
    }
}
