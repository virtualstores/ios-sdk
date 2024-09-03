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
  func upload(visitId: Int64, positions: [String:[RecordedPosition]], completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, scanEvent: ScanEvent, completion: @escaping (Error?) -> ())
  func upload(visitId: Int64, triggerEvent: PostTriggerEventRequest, completion: @escaping (Error?) -> ())
}

class AnalyticsRepository {
  private let api: IAnalyticsApi = AnalyticsApi()
  private var visitId: Int64?
}

extension AnalyticsRepository: IAnalyticsRepository {
  var activeVisitId: Int64? { visitId }

  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String : String], metaData: [String : String], completion: @escaping (Result<Int64, Error>) -> ()) {
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

  func stopVisit(visitId: Int64, completion: @escaping (Error?) -> ()) {
    api.stopVisit(visitId: visitId) { [weak self] (error) in
      if error == nil {
        self?.visitId = nil
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

  func upload(visitId: Int64, positions: [String:[RecordedPosition]], completion: @escaping (Error?) -> ()) {
    api.upload(visitId: visitId, positions: positions, completion: completion)
  }

  func upload(visitId: Int64, scanEvent: ScanEvent, completion: @escaping (Error?) -> ()) {
    api.upload(visitId: visitId, scanEvent: scanEvent, completion: completion)
  }

  func upload(visitId: Int64, triggerEvent: PostTriggerEventRequest, completion: @escaping (Error?) -> ()) {
    api.upload(visitId: visitId, triggerEvent: triggerEvent, completion: completion)
  }
}
