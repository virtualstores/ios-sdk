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
    guard let storeId = try? storeRepository.activeStore.statServerConnection.storeId else { completion(.failure(TT2Error.missingData)); return }
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

class UploadZoneSummaryForActiveVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(summary: [String:AnalyticsZoneSummaryBusiness.ZoneCountsDTO], completion: @escaping (Error?) -> ()) {
    guard let id = repository.activeVisitId else { completion(TT2AnalyticsError.visitNotStarted); return }
    repository.upload(visitId: id, summary: summary, completion: completion)
  }
}
