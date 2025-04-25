//
//  AnalyticsUseCases.swift
//
//
//  Created by Théodore Roos on 2024-06-04.
//

import Foundation
import VSFoundation

class CreateVisitUseCase {
  @Inject var repository: IAnalyticsRepository
  @Inject var storeRepository: IStoreRepository

  func invoke(deviceInformation: DeviceInformation, tags: [String : String], metaData: [String : String], completion: @escaping (Result<Int64, Error>) -> ()) {
    guard let storeId = storeRepository.activeStore.statServerConnection.storeId else { completion(.failure(VSTT2Error.missingData)); return }
    repository.createVisit(
      storeId: storeId,
      deviceInformation: deviceInformation,
      tags: tags,
      metaData: metaData,
      completion: completion
    )
  }
}

class GetActiveVisitIDUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke() -> Int64? {
    repository.activeVisitId
  }
}

class StopVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(completion: @escaping (Error?) -> ()) {
    guard let id = repository.activeVisitId else { completion(TT2AnalyticsError.visitNotStarted); return }
    repository.stopVisit(visitId: id, completion: completion)
  }
}

class UpdateTagsForActiveVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(tags: [String:String], completion: @escaping (Error?) -> ()) {
    guard let id = repository.activeVisitId else { completion(TT2AnalyticsError.visitNotStarted); return }
    repository.update(visitId: id, tags: tags, completion: completion)
  }
}

class UploadGeopositionsForActiveVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ()) {
    guard let id = repository.activeVisitId else { completion(TT2AnalyticsError.visitNotStarted); return }
    repository.upload(visitId: id, geopositions: geopositions, completion: completion)
  }
}

class UploadGeopositionsForVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(visitId: Int64, geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ()) {
    repository.upload(visitId: visitId, geopositions: geopositions, completion: completion)
  }
}

class UploadSavedGeopositionsUseCase {
  @Inject var persistence: PersistenceManager
  @Inject var repository: IAnalyticsRepository

  let semaphore = DispatchSemaphore(value: 1)

  func invoke() {
    let geo = persistence
      .getGeoPositions()
    print("COUNT GEO", geo.count)
    geo
      .forEach { (parameters) in
        DispatchQueue.global(qos: .background).async { [weak self] in
          guard let self = self else { return }
          semaphore.wait()
          upload(parameters: parameters)
        }
      }
  }

  private func upload(parameters: UploadGeoPositionsParameters, attempt: Double = 0) {
    guard attempt < 10 else { semaphore.signal(); return }
    repository.upload(parameters: parameters) { [weak self] (error) in
      if let error = error {
        print("GEO ERROR", error)
        print("CONNECTION", parameters.config.connection.tt2DataServer)
        Thread.sleep(forTimeInterval: 3 * (attempt + 1))
        self?.upload(parameters: parameters, attempt: attempt + 1)
      } else {
        self?.persistence.delete(with: parameters.requestId)
        self?.semaphore.signal()
      }
    }
  }
}

class UploadPositionsForVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(parameters: UploadPositionsParameters, completion: @escaping (Error?) -> ()) {
    repository.upload(parameters: parameters, completion: completion)
  }
}

class UploadScanEventForActiveVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(event: ScanEvent, completion: @escaping (Error?) -> ()) {
    guard let id = repository.activeVisitId else { completion(TT2AnalyticsError.visitNotStarted); return }
    repository.upload(visitId: id, scanEvent: event, completion: completion)
  }
}

class UploadTriggerEventForActiveVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(request: PostTriggerEventRequest, completion: @escaping (Error?) -> ()) {
    guard let id = repository.activeVisitId else { completion(TT2AnalyticsError.visitNotStarted); return }
    repository.upload(visitId: id, triggerEvent: request, completion: completion)
  }
}

class UploadVisitScoreForActiveVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(visitScore: VisitScore, completion: @escaping (Error?) -> ()) {
    guard let id = repository.activeVisitId else { completion(TT2AnalyticsError.visitNotStarted); return }
    repository.upload(visitId: id, visitScore: visitScore, completion: completion)
  }
}
