//
//  AnalyticsRepository.swift
//
//
//  Created by Théodore Roos on 2024-06-03.
//

import Foundation
import VSFoundation

protocol IAnalyticsRepository {
  var activeVisitId: Int64? { get }
  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String : String], metaData: [String : String], completion: @escaping (Result<Int64, Error>) -> ())
  func stopVisit(visitId: Int64, completion: @escaping (Error?) -> ())
  func update(visitId: Int64, tags: [String:String], completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ())
  func upload(parameters: UploadGeoPositionsParameters, completion: @escaping (Error?) -> ())
  func upload(parameters: UploadPositionsParameters, completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, scanEvent: ScanEvent, completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, triggerEvent: PostTriggerEventRequest, completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, visitScore: VisitScore, completion: @escaping (Error?) -> ())
}

class AnalyticsRepository {
  private let api: IAnalyticsApi = AnalyticsApi()
  private var visitId: Int64?
  private var isMocked: Bool = false
  private var sessionId: Int64 { sessionIds[visitId ?? 0] ?? 0 }
  private var sessionIds: [Int64: Int64] {
    get { UserDefaults.standard.dictionary(forKey: "sessionIds") as? [Int64: Int64] ?? [:] }
    set { UserDefaults.standard.set(newValue, forKey: "sessionIds") }
  }
}

extension AnalyticsRepository: IAnalyticsRepository {
  var activeVisitId: Int64? { visitId }

  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String : String], metaData: [String : String], completion: @escaping (Result<Int64, Error>) -> ()) {
    if isMocked {
      completion(.success(visitId!))
    } else {
      api.createVisit(storeId: storeId, deviceInformation: deviceInformation, tags: tags, metaData: metaData) { [weak self] (result) in
        switch result {
        case .success(let visitId):
          self?.visitId = visitId
          completion(.success(visitId))
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }

  func newSession() {
    guard let id = visitId else { return }
    sessionIds[id]
  }

  func set(visitId: Int64, isMocked: Bool) {
    self.visitId = visitId
    self.isMocked = isMocked
  }

  func stopVisit(visitId: Int64, completion: @escaping (Error?) -> ()) {
    api.stopVisit(visitId: visitId) { [weak self] (error) in
      guard let self = self else { return }
      if error == nil, !(isMocked) {
        self.visitId = nil
      }
      completion(error)
    }
  }

  func update(visitId: Int64, tags: [String:String], completion: @escaping (Error?) -> ()) {
    api.update(visitId: visitId, tags: tags, completion: completion)
  }

  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ()) {
    api.upload(visitId: visitId, geopositions: geopositions, completion: completion)
  }

  func upload(parameters: UploadGeoPositionsParameters, completion: @escaping (Error?) -> ()) {
    api.upload(parameters: parameters, completion: completion)
  }

  func upload(parameters: UploadPositionsParameters, completion: @escaping (Error?) -> ()) {
    api.upload(parameters: parameters, completion: completion)
  }

  func upload(visitId: Int64, scanEvent: ScanEvent, completion: @escaping (Error?) -> ()) {
    api.upload(visitId: visitId, scanEvent: scanEvent, completion: completion)
  }

  func upload(visitId: Int64, triggerEvent: PostTriggerEventRequest, completion: @escaping (Error?) -> ()) {
    api.upload(visitId: visitId, triggerEvent: triggerEvent, completion: completion)
  }

  func upload(visitId: Int64, visitScore: VisitScore, completion: @escaping (Error?) -> ()) {
    api.upload(visitId: visitId, visitScore: visitScore, completion: completion)
  }
}
