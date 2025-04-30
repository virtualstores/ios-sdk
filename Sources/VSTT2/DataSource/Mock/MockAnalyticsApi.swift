//
//  AnalyticsApi.swift
//
//
//  Created by Théodore Roos on 2024-06-04.
//

import Combine
import Foundation
import VSFoundation

class MockAnalyticsApi {
  @Inject private var manager: PersistenceManager
  private let createVisitService = CreateVisitService(with: NetworkManager())
  private let stopVisitService = StopVisitService(with: NetworkManager())
  private let tagsVisitService = TagsVisitService(with: NetworkManager())
  private let uploadGeopositionsService = UploadGeoPositionsService(with: NetworkManager())
  private let uploadPositionsService = UploadPositionsService(with: NetworkManager())
  private let uploadScanEventsService = UploadScanEventsService(with: NetworkManager())
  private let uploadTriggersService = UploadTriggersService(with: NetworkManager())
  private let uploadVisitScoreService = UploadVisitScoreService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension MockAnalyticsApi: IAnalyticsApi {
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

  private func uploadGeopositionsService(requestId: String, completion: @escaping (Error?) -> ()) {
    manager.getGeoPositions().forEach { (params) in
      uploadGeopositionsService
        .call(with: params)
        .sink { (result) in
          switch result {
          case .finished: break
          case .failure(let error):
            if requestId == params.requestId {
              completion(error)
            }
          }
        } receiveValue: { [weak self] (_) in
          self?.manager.delete(with: params.requestId)
          if requestId == params.requestId {
            completion(nil)
          }
        }.store(in: &cancellable)
    }
  }
  
  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ()) {
    let params = UploadGeoPositionsParameters(
      visitId: visitId,
      requestId: UUID().uuidString.uppercased(),
      positions: geopositions
    )
    manager.save(geoposition: params)
    //uploadGeopositionsService(requestId: params.requestId, completion: completion)
    uploadGeopositionsService
      .call(with: params)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
      } receiveValue: { [weak self] (_) in
        self?.manager.delete(with: params.requestId)
        completion(nil)
      }.store(in: &cancellable)
  }

  func upload(parameters: UploadGeoPositionsParameters, completion: @escaping (Error?) -> ()) {
    var test: AnyCancellable?
    test = uploadGeopositionsService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(error)
        }
        if let test = test {
          self.cancellable.remove(test)
        }
      } receiveValue: { (_) in
        completion(nil)
      }
    test?
      .store(in: &cancellable)
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
}
