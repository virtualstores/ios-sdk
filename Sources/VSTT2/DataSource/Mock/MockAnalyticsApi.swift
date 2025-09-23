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
  enum AnalyticsError: Error {
    case unknown
  }
}

extension MockAnalyticsApi: IAnalyticsApi {
  func createVisit(storeId: Int64, deviceInformation: DeviceInformation, tags: [String:String], metaData: [String:String], completion: @escaping (Result<Int64, Error>) -> ()) {
    completion(.failure(AnalyticsError.unknown))
  }

  func stopVisit(visitId: Int64, completion: @escaping (Error?) -> ()) {
    completion(AnalyticsError.unknown)
  }

  func update(visitId: Int64, tags: [String:String], completion: @escaping (Error?) -> ()) {
    completion(AnalyticsError.unknown)
  }
  
  func upload(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ()) {
    manager.save(geoposition: UploadGeoPositionsParameters(
      visitId: visitId,
      requestId: UUID().uuidString.uppercased(),
      positions: geopositions
    ))
    completion(AnalyticsError.unknown)
  }

  func upload(parameters: UploadGeoPositionsParameters, completion: @escaping (Error?) -> ()) {
    completion(AnalyticsError.unknown)
  }

  func upload(parameters: UploadPositionsParameters, completion: @escaping (Error?) -> ()) {
    completion(AnalyticsError.unknown)
  }

  func upload(visitId: Int64, scanEvent: ScanEvent, completion: @escaping (Error?) -> ()) {
    completion(AnalyticsError.unknown)
  }

  func upload(visitId: Int64, triggerEvent: PostTriggerEventRequest, completion: @escaping (Error?) -> ()) {
    completion(AnalyticsError.unknown)
  }

  func upload(visitId: Int64, visitScore: VisitScore, completion: @escaping (Error?) -> ()) {
    completion(AnalyticsError.unknown)
  }
}
