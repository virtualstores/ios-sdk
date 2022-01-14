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

    private let store: Store
    private var visitId: Int64?
    private var timeFormatter: DateFormatter = DateFormatter()
    private var cancellable = Set<AnyCancellable>()

    var recordedPositions: Dictionary<String, [RecordedPosition]> = [:]
    var isRecording: Bool = false

    init(store: Store) {
        self.store = store

        self.timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    }

    public func startVisit(deviceInformation: DeviceInformation, tags: [String: String] = [:], metaData: [String: String] = [:]) {
        let date = self.timeFormatter.string(from: Date())
        let parameters = CreateVisitsParameters(apiKey: store.serverConnection.apiKey,
                                                requestId: UUID().uuidString.uppercased(),
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
            }).store(in: &cancellable)
    }

    public func startCollectingHeatMapData() throws {
        guard self.visitId != nil else {
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
}

private extension TT2AnalyticsManager {
    func recordPosition(rtlsOptionId: Int64, point: CGPoint) {
        let id = String(rtlsOptionId)
        if self.recordedPositions[id] == nil {
            self.recordedPositions[id] = []
        }
        
        let recordedPosition = RecordedPosition(x: Double(point.x), y: Double(point.y), timeStamp: self.timeFormatter.string(from: Date()))
        self.recordedPositions[id]?.append(recordedPosition)
        
        if self.checkIfPartialUpload() {
            self.uploadData(recordedPositions: self.recordedPositions)
            self.recordedPositions.removeAll()
        }
    }
    
    private func checkIfPartialUpload() -> Bool {
        var numberOfRecordedPositions: Int = 0
        self.recordedPositions.forEach { (key, value) in
            numberOfRecordedPositions += value.count
        }
        
        return true
      //  return numberOfRecordedPositions > self.uploadThreshold
    }
    
    private func uploadData(recordedPositions: Dictionary<String, [RecordedPosition]>) {
        guard let visitId = visitId else { return }
     //   uploadWorker.upload(visitId: id, recordedPositions: WorkerPositionData(data: recordedPositions), statServerConnection: store.statConnection)
        let parameters = UploadPositionsParameters(visitId: visitId, requestId: "1", positionGrps: recordedPositions)
        uploadPositionsService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { (data) in
                // Publish data
            }).store(in: &cancellable)
    }
}
