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

final public class TT2AnalyticsManager: TT2Analytics {
    @Inject var createVisitsService: CreateVisitsService
    @Inject var uploadPositionsService: UploadPositionsService
    @Inject var uploadTriggersService: UploadTriggersService
    @Inject var positionUploadWorker: PositionUploadWorker

    private var store: Store?
    private var uploadThreshold = 0
    private var visitId: Int64?
    private var requestId: String?
    private var timeFormatter: DateFormatter = DateFormatter()
    private var cancellable = Set<AnyCancellable>()

    /// now we are uploading positions each time when they are 100
    private var recordedPositionsCount = 0
    private var isRecording: Bool = false

    public init() {}

    public func setup(with store: Store, uploadThreshold: Int = 100) {
        self.store = store
        self.uploadThreshold = uploadThreshold
        self.requestId = UUID().uuidString.uppercased()

        self.timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    }

    public func startVisit(deviceInformation: DeviceInformation, tags: [String: String] = [:], metaData: [String: String] = [:]) {
        guard let store = store, let requestId = requestId else { return }

        let date = self.timeFormatter.string(from: Date())
        let parameters = CreateVisitsParameters(apiKey: store.serverConnection.apiKey,
                                                requestId: requestId,
                                                storeId: store.id,
                                                start: date,
                                                stop: date,
                                                deviceInformation: deviceInformation,
                                                tags: tags,
                                                metaData: metaData)
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
                do {
                    try self?.startCollectingHeatMapData()
                } catch {
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
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
        do {
            guard let points = try positionUploadWorker.getPoints() else { return }
            self.uploadData(recordedPositions: points)
            self.recordedPositionsCount = 0
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "GetPoints from SQLite error")
        }
    }

    public func onNewPositionBundle(point: CGPoint) {
        if isRecording {
            // navigationSpace.id
            recordPosition(rtlsOptionId: 1, point: point)
        }
    }
}

private extension TT2AnalyticsManager {
    func recordPosition(rtlsOptionId: Int64, point: CGPoint) {
        let id = String(rtlsOptionId)

        recordedPositionsCount += 1
        positionUploadWorker.insert(id: id, x: Double(point.x), y: Double(point.y), time: self.timeFormatter.string(from: Date()), uploadStatus: .pending)

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

    private func uploadData(recordedPositions: [String: [RecordedPosition]]) {
        guard let visitId = visitId, let requestId = requestId  else { return }

        let parameters = UploadPositionsParameters(visitId: visitId, requestId: requestId, positionGrps: recordedPositions)
        uploadPositionsService
            .call(with: parameters)
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .finished:
                    self?.positionUploadWorker.removePoints()
                case .failure(let error):
                    self?.positionUploadWorker.updatePointsAfterUploadingFail()
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] (_) in
                Logger.init(verbosity: .debug).log(message: "Recorded Positions Uploaded")
                self?.positionUploadWorker.updatePointsAfterUploading()
            }).store(in: &cancellable)
    }

    private func uploadTriggerEvents(request: PostTriggerEventRequest) {
        guard let visitId = visitId, let requestId = requestId else { return }

        let parameters = UploadTriggersParameters(visitId: visitId, requestId: requestId, request: request)

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
               /// use data
            }).store(in: &cancellable)
    }

    private func uploadScanEvents(request: PostTriggerEventRequest) {
        guard let visitId = visitId, let requestId = requestId else { return }

        let parameters = UploadTriggersParameters(visitId: visitId, requestId: requestId, request: request)

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
                /// use data
            }).store(in: &cancellable)
    }
}
