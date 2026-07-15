//
//  AnalyticsRepository.swift
//
//
//  Created by Théodore Roos on 2024-06-03.
//

import Combine
import Foundation
import VSFoundation

protocol IAnalyticsRepository: Disposable {
  var activeVisitId: Int64? { get }
  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String : String], metaData: [String : String]) -> AnyPublisher<Int64, Error>
  func stopVisit(visitId: Int64) -> AnyPublisher<Void, Error>
  func update(visitId: Int64, tags: [String:String]) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]]) -> AnyPublisher<Void, Error>
  func upload(parameters: UploadPositionsParameters) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, requestId: String, event: ScanEvent) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, requestId: String, event: SyncEvent) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, requestId: String, event: PostTriggerEventRequest) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, visitScore: VisitScore) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, summary: [String : AnalyticsZoneSummaryBusiness.ZoneCountsDTO]) -> AnyPublisher<Void, Error>
}

class AnalyticsRepository {
  private let tag = "AnalyticsRepository"
  private let api: IAnalyticsApi = AnalyticsApi()
  private var visitId: Int64?

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }
}

extension AnalyticsRepository: IAnalyticsRepository {
  var activeVisitId: Int64? { visitId }

  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    visitId = nil
  }

  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String : String], metaData: [String : String]) -> AnyPublisher<Int64, Error> {
    api.createVisit(storeId: storeId, deviceInformation: deviceInformation, tags: tags, metaData: metaData)
      .handleEvents(receiveOutput: { [weak self] in self?.visitId = $0 })
      .eraseToAnyPublisher()
  }

  func stopVisit(visitId: Int64) -> AnyPublisher<Void, Error> {
    api.stopVisit(visitId: visitId)
      .handleEvents(receiveCompletion: { [weak self] in
        guard case .finished = $0 else { return }
        self?.visitId = nil
      })
      .eraseToAnyPublisher()
  }

  func update(visitId: Int64, tags: [String:String]) -> AnyPublisher<Void, Error> {
    api.update(visitId: visitId, tags: tags)
  }

  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]]) -> AnyPublisher<Void, Error> {
    api.upload(visitId: visitId, geopositions: geopositions)
  }

  func upload(parameters: UploadPositionsParameters) -> AnyPublisher<Void, Error> {
    api.upload(parameters: parameters)
  }

  func upload(visitId: Int64, requestId: String, event: ScanEvent) -> AnyPublisher<Void, Error> {
    api.upload(visitId: visitId, event: event)
  }

  func upload(visitId: Int64, requestId: String, event: SyncEvent) -> AnyPublisher<Void, Error> {
    api.upload(parameters: .init(visitId: visitId, requestId: requestId, event: event))
  }

  func upload(visitId: Int64, requestId: String, event: PostTriggerEventRequest) -> AnyPublisher<Void, Error> {
    api.upload(parameters: .init(visitId: visitId, requestId: requestId, event: event))
  }

  func upload(visitId: Int64, visitScore: VisitScore) -> AnyPublisher<Void, Error> {
    api.upload(visitId: visitId, visitScore: visitScore)
  }

  func upload(visitId: Int64, summary: [String : AnalyticsZoneSummaryBusiness.ZoneCountsDTO]) -> AnyPublisher<Void, Error> {
    api.upload(visitId: visitId, summary: summary)
  }
}

class AnalyticsBufferRepository: Disposable {
  var syncEvents: [SyncEvent] = []
  var triggerEvents: [PostTriggerEventRequest] = []
  var scanEvents: [ScanEvent] = []

  func dispose() {
    reset()
  }

  func append(_ event: SyncEvent) {
    syncEvents.append(event)
  }

  func append(_ event: PostTriggerEventRequest) {
    triggerEvents.append(event)
  }

  func append(_ event: ScanEvent) {
    scanEvents.append(event)
  }

  func startVisit() -> (syncEvents: [SyncEvent], triggerEvents: [PostTriggerEventRequest], scanEvents: [ScanEvent]) {
    defer { reset() }
    return (syncEvents, triggerEvents, scanEvents)
  }

  func reset() {
    syncEvents.removeAll()
    triggerEvents.removeAll()
    scanEvents.removeAll()
  }
}
