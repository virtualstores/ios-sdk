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
    @Inject var createVisitsService: CreateVisitsService
    @Inject var uploadPositionsService: UploadPositionsService
    @Inject var uploadTriggersService: UploadTriggersService
    @Inject var uploadScanEventsService: UploadScanEventsService
    @Inject var positionUploadWorker: PositionUploadWorker
    @Inject var zoneManager: TT2ZoneManager
    @Inject public var evenManager: TT2EventManager

    private var store: Store?
    private var uploadThreshold = 0
    private var visitId: Int64?
    private var apiKey: String?
    private var cancellable = Set<AnyCancellable>()
    private var zoneEnterCancellable: AnyCancellable?
    private var zoneExitCancellable: AnyCancellable?
    private var isRecording: Bool = false
    private var rtlsOptionId: Int64?
    /// now we are uploading positions each time when they are 100
    private var recordedPositionsCount = 0
    private var config: EnvironmentConfig?

    public var startHeatMapCollectingPublisher: CurrentValueSubject<Void?, Never> = .init(nil)
    
    public init() {}

    public func setup(with store: Store, rtlsOptionId: Int64?, uploadThreshold: Int = 100, config: EnvironmentConfig?) {
        self.store = store
        self.apiKey = store.statServerConnection.apiKey
        self.uploadThreshold = uploadThreshold
        self.rtlsOptionId = rtlsOptionId
        self.config = config
        bindPublishers()
    }

    public func startVisit(deviceInformation: DeviceInformation, tags: [String: String] = [:], metaData: [String: String] = [:]) {
        guard let storeId = store?.statServerConnection.storeId, let apiKey = store?.statServerConnection.apiKey else { return }

        let date = DateFormatter.standardFormatter.string(from: Date())
        let parameters = CreateVisitsParameters(apiKey: apiKey,
                                                requestId: UUID().uuidString.uppercased(),
                                                storeId: storeId,
                                                start: date,
                                                stop: date,
                                                deviceInformation: deviceInformation,
                                                tags: tags,
                                                metaData: metaData,
                                                config: config)
        createVisitsService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] (data) in
                self?.visitId = data.visitId
                self?.startHeatMapCollectingPublisher.send(())
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
        guard let points = positionUploadWorker.getAllPoints() else { return }
        
        self.uploadData(recordedPositions: points, recordingStoped: true)
        self.recordedPositionsCount = 0
    }

    internal func onNewPositionBundle(point: CGPoint) {
        if isRecording {
            recordPosition(rtlsOptionId: self.rtlsOptionId ?? 0, point: point)
            zoneManager.onNewPosition(currentPosition: point)
            evenManager.onNewPosition(currentPosition: point)
        }
    }
    
    public func addTriggerEvent(for event: TriggerEvent) {
        let event = postTriggerEvent(for: event)
        uploadTriggerEvents(request: event)
    }
    
    public func bindPublishers() {
        self.zoneEnterCancellable = zoneManager.zoneEnteredPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneEnteredPublisher error")
            } receiveValue: { [weak self] data in
                guard let event = self?.postTriggerEvent(for: data) else { return }
                
                self?.uploadTriggerEvents(request: event)
            }
        
        self.zoneExitCancellable = zoneManager.zoneExitedPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneExitedPublisher error")
            } receiveValue: { [weak self] data in
                guard let event = self?.postTriggerEvent(for: data) else { return }
                
                self?.uploadTriggerEvents(request: event)
            }
    }
    
    private func postTriggerEvent(for event: TriggerEvent) ->PostTriggerEventRequest {
        let eventType = event.eventType.getTrigger()
        let timestamp = DateFormatter.standardFormatter.string(from: event.timestamp)
        return  PostTriggerEventRequest(rtlsOptionsId: event.rtlsOptionsId, name: event.name,
                                        timeStamp: timestamp,
                                        userPosition: event.userPosition,
                                        appTrigger: eventType.appTrigger?.asPostTrigger,
                                        coordinateTrigger: eventType.coordinateTrigger?.asPostTrigger,
                                        shelfTrigger: eventType.shelfTrigger?.asPostTrigger,
                                        zoneTrigger: eventType.zoneTrigger?.asPostTrigger,
                                        tags: event.tags,
                                        metaData: event.metaData)
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
    private func uploadData(recordedPositions: [String: [RecordedPosition]], recordingStoped: Bool = false) {
        guard let visitId = visitId, let apiKey = apiKey else { return }

        let parameters = UploadPositionsParameters(apiKey: apiKey, visitId: visitId, requestId: UUID().uuidString.uppercased(), positionGrps: recordedPositions, config: config)

        uploadPositionsService
            .call(with: parameters)
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .finished:
                    if recordingStoped {
                        self?.positionUploadWorker.removeAllPoints()
                    } else {
                        self?.positionUploadWorker.removePoints()
                    }
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
        guard let visitId = visitId, let apiKey = apiKey else { return }

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
                Logger.init(verbosity: .debug).log(message: "uploadTriggerEvents success")
            }).store(in: &cancellable)
    }

    private func uploadScanEvents() {
        guard let visitId = visitId, let apiKey = apiKey else { return }
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
