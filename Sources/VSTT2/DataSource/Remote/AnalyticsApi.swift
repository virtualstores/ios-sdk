//
//  AnalyticsApi.swift
//
//
//  Created by Théodore Roos on 2024-06-04.
//

import Combine
import Foundation
import VSFoundation

protocol IAnalyticsApi {
  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String:String], metaData: [String:String]) -> AnyPublisher<Int64, Error>
  func stopVisit(visitId: Int64) -> AnyPublisher<Void, Error>
  func update(visitId: Int64, tags: [String:String]) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]]) -> AnyPublisher<Void, Error>
  func upload(parameters: UploadPositionsParameters) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, event: ScanEvent) -> AnyPublisher<Void, Error>
  func upload(parameters: UploadSyncEventParameters) -> AnyPublisher<Void, Error>
  func upload(parameters: UploadTriggersParameters) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, visitScore: VisitScore) -> AnyPublisher<Void, Error>
  func upload(visitId: Int64, summary: [String : AnalyticsZoneSummaryBusiness.ZoneCountsDTO]) -> AnyPublisher<Void, Error>
}

class AnalyticsApi {
  private let tag = "AnalyticsApi"
  private let createVisitService = CreateVisitService(with: NetworkManager())
  private let stopVisitService = StopVisitService(with: NetworkManager())
  private let tagsVisitService = TagsVisitService(with: NetworkManager())
  private let uploadGeopositionsService = UploadGeoPositionsService(with: NetworkManager())
  private let uploadPositionsService = UploadPositionsService(with: NetworkManager())
  private let uploadScanEventsService = UploadScanEventsService(with: NetworkManager())
  private let uploadSyncEventsService = UploadSyncEventsService(with: NetworkManager())
  private let uploadTriggersService = UploadTriggersService(with: NetworkManager())
  private let uploadVisitScoreService = UploadVisitScoreService(with: NetworkManager())
  private let uploadZoneSummmaryService = UploadZoneSummaryService(with: NetworkManager())
}

extension AnalyticsApi: IAnalyticsApi {
  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String:String], metaData: [String:String]) -> AnyPublisher<Int64, Error> {
    let date = DateFormatter.standardFormatter.string(from: Date())
    return createVisitService
      .call(with: CreateVisitParameters(
        requestId: UUID().uuidString.uppercased(),
        storeId: storeId,
        start: date,
        stop: date,
        deviceInformation: deviceInformation,
        tags: tags,
        metaData: metaData
      ))
      .map { $0.visitId }
      .eraseToAnyPublisher()
  }

  func stopVisit(visitId: Int64) -> AnyPublisher<Void, Error> {
    stopVisitService
      .call(with: .init(
        requestId: UUID().uuidString.uppercased(),
        visitId: visitId,
        stopTimestamp: DateFormatter.standardFormatter.string(from: Date())
      ))
  }

  func update(visitId: Int64, tags: [String:String]) -> AnyPublisher<Void, Error> {
    tagsVisitService
      .call(with: .init(
        requestId: UUID().uuidString.uppercased(),
        visitId: visitId,
        tags: tags
      ))
  }

  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]]) -> AnyPublisher<Void, Error> {
    uploadGeopositionsService
      .call(with: .init(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        positions: geopositions
      ))
  }

  func upload(parameters: UploadPositionsParameters) -> AnyPublisher<Void, Error> {
    uploadPositionsService
      .call(with: parameters)
  }

  func upload(visitId: Int64, event: ScanEvent) -> AnyPublisher<Void, Error> {
    uploadScanEventsService
      .call(with: .init(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        scanEvent: event
      ))
  }

  func upload(parameters: UploadSyncEventParameters) -> AnyPublisher<Void, Error> {
    uploadSyncEventsService
      .call(with: parameters)
  }

  func upload(parameters: UploadTriggersParameters) -> AnyPublisher<Void, Error> {
    uploadTriggersService
      .call(with: parameters)
  }

  func upload(visitId: Int64, visitScore: VisitScore) -> AnyPublisher<Void, Error> {
    uploadVisitScoreService
      .call(with: .init(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        visitScore: visitScore
      ))
  }

  func upload(visitId: Int64, summary: [String : AnalyticsZoneSummaryBusiness.ZoneCountsDTO]) -> AnyPublisher<Void, Error> {
    uploadZoneSummmaryService
      .call(with: .init(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        summary: summary
      ))
  }
}
