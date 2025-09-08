//
//  AnalyticsApi.swift
//
//
//  Created by Théodore Roos on 2024-06-04.
//

import Combine
import Foundation
import VSFoundation

protocol IAnalyticsApi: Disposable {
  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String:String], metaData: [String:String], completion: @escaping (Result<Int64, Error>) -> ())
  func stopVisit(visitId: Int64, completion: @escaping (Error?) -> ())
  func update(visitId: Int64, tags: [String:String], completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ())
  func upload(parameters: UploadPositionsParameters, completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, scanEvent: ScanEvent, completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, triggerEvent: PostTriggerEventRequest, completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, visitScore: VisitScore, completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, summary: [String : AnalyticsZoneSummaryBusiness.ZoneCountsDTO], completion: @escaping (Error?) -> ())
}

class AnalyticsApi {
  private let tag = "AnalyticsApi"
  private let createVisitService = CreateVisitService(with: NetworkManager())
  private let stopVisitService = StopVisitService(with: NetworkManager())
  private let tagsVisitService = TagsVisitService(with: NetworkManager())
  private let uploadGeopositionsService = UploadGeoPositionsService(with: NetworkManager())
  private let uploadPositionsService = UploadPositionsService(with: NetworkManager())
  private let uploadScanEventsService = UploadScanEventsService(with: NetworkManager())
  private let uploadTriggersService = UploadTriggersService(with: NetworkManager())
  private let uploadVisitScoreService = UploadVisitScoreService(with: NetworkManager())
  private let uploadZoneSummmaryService = UploadZoneSummaryService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension AnalyticsApi: IAnalyticsApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellable.removeAll()
  }
  
  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String:String], metaData: [String:String], completion: @escaping (Result<Int64, Error>) -> ()) {
    let date = DateFormatter.standardFormatter.string(from: Date())
    createVisitService
      .call(with: CreateVisitParameters(
        requestId: UUID().uuidString.uppercased(),
        storeId: storeId,
        start: date,
        stop: date,
        deviceInformation: deviceInformation,
        tags: tags,
        metaData: metaData
      )).sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      } receiveValue: { (data) in
        completion(.success(data.visitId))
      }.store(in: &cancellable)
  }

  func stopVisit(visitId: Int64, completion: @escaping (Error?) -> ()) {
    stopVisitService
      .call(with: StopVisitParameters(
        requestId: UUID().uuidString.uppercased(),
        visitId: visitId,
        stopTimestamp: DateFormatter.standardFormatter.string(from: Date())
      )).sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { (_) in
        completion(nil)
      }.store(in: &cancellable)
  }

  func update(visitId: Int64, tags: [String:String], completion: @escaping (Error?) -> ()) {
    tagsVisitService
      .call(with: TagsVisitParameters(
        requestId: UUID().uuidString.uppercased(),
        visitId: visitId,
        tags: tags
      )).sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { (_) in
        completion(nil)
      }.store(in: &cancellable)
  }

  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ()) {
    uploadGeopositionsService
      .call(with: UploadGeoPositionsParameters(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        positions: geopositions
      )).sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { (_) in
        completion(nil)
      }.store(in: &cancellable)
  }

  func upload(parameters: UploadPositionsParameters, completion: @escaping (Error?) -> ()) {
    uploadPositionsService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { (_) in
        completion(nil)
      }.store(in: &cancellable)
  }

  func upload(visitId: Int64, scanEvent: ScanEvent, completion: @escaping (Error?) -> ()) {
    uploadScanEventsService
      .call(with: UploadScanEventsParameters(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        scanEvent: scanEvent
      )).sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { (_) in
        completion(nil)
      }.store(in: &cancellable)
  }

  func upload(visitId: Int64, triggerEvent: PostTriggerEventRequest, completion: @escaping (Error?) -> ()) {
    uploadTriggersService
      .call(with: UploadTriggersParameters(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        request: triggerEvent
      )).sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { (_) in
        completion(nil)
      }.store(in: &cancellable)
  }

  func upload(visitId: Int64, visitScore: VisitScore, completion: @escaping (Error?) -> ()) {
    uploadVisitScoreService
      .call(with: UploadVisitScoreParameters(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        visitScore: visitScore
      )).sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { (_) in
        completion(nil)
      }.store(in: &cancellable)
  }

  func upload(visitId: Int64, summary: [String : AnalyticsZoneSummaryBusiness.ZoneCountsDTO], completion: @escaping (Error?) -> ()) {
    uploadZoneSummmaryService
      .call(with: .init(
        visitId: visitId,
        requestId: UUID().uuidString.uppercased(),
        summary: summary
      ))
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { (_) in
        completion(nil)
      }.store(in: &cancellable)
  }
}
