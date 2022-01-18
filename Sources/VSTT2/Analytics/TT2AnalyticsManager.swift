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

    private var store: Store?
    private var uploadThreshold = 0
    private var visitId: Int64?
    private var requestId: String?
    private var timeFormatter: DateFormatter = DateFormatter()
    private var cancellable = Set<AnyCancellable>()

    var recordedPositions: [String: [RecordedPosition]] = [:]
    var isRecording: Bool = false

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
        self.uploadData(recordedPositions: self.recordedPositions)
        self.visitId = nil
        self.recordedPositions.removeAll()
    }
    
    public func onNewPositionBundle(point: CGPoint) {
        if isRecording {
            //navigationSpace.id
          recordPosition(rtlsOptionId: 1, point: point)
        }
    }
}

private extension TT2AnalyticsManager {
    func recordPosition(rtlsOptionId: Int64, point: CGPoint) {
        let id = String(rtlsOptionId)
        if self.recordedPositions[id] == nil {
            self.recordedPositions[id] = []
        }

        let recordedPosition = RecordedPosition(xPosition: Double(point.x), yPosition: Double(point.y), timeStamp: self.timeFormatter.string(from: Date()))
        self.recordedPositions[id]?.append(recordedPosition)

        if self.checkIfPartialUpload() {
            self.uploadData(recordedPositions: self.recordedPositions)
            self.recordedPositions.removeAll()
        }
    }

    private func checkIfPartialUpload() -> Bool {
        var numberOfRecordedPositions: Int = 0
        self.recordedPositions.forEach { (_, value) in
            numberOfRecordedPositions += value.count
        }

        return numberOfRecordedPositions > self.uploadThreshold
    }

    private func uploadData(recordedPositions: [String: [RecordedPosition]]) {
        guard let visitId = visitId, let requestId = requestId  else { return }
     //   uploadWorker.upload(visitId: id, recordedPositions: WorkerPositionData(data: recordedPositions), statServerConnection: store.statConnection)
        let parameters = UploadPositionsParameters(visitId: visitId, requestId: requestId, positionGrps: recordedPositions)
        uploadPositionsService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { (_) in
                Logger.init(verbosity: .debug).log(message: "Recorded Positions Uploaded")
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
            }, receiveValue: { (data) in
                print(data)
            }).store(in: &cancellable)
    }
}
