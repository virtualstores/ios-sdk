//
//  AnalyticsUseCases.swift
//
//
//  Created by Théodore Roos on 2024-06-04.
//

import Combine
import Foundation
import VSFoundation

class BufferOrPersistEventForActiveVisitUseCase {
  @Inject var repository: IAnalyticsRepository
  @Inject var buffer: AnalyticsBufferRepository
  @Inject var persistence: IPersistenceRepository

  func invoke(event: ScanEvent) {
    guard let id = repository.activeVisitId else { buffer.append(event); return }
    persistence.save(event, visitId: id)
  }

  func invoke(event: SyncEvent) {
    guard let id = repository.activeVisitId else { buffer.append(event); return }
    persistence.save(event, visitId: id)
  }

  func invoke(event: PostTriggerEventRequest) {
    guard let id = repository.activeVisitId else { buffer.append(event); return }
    persistence.save(event, visitId: id)
  }
}

class CreateVisitUseCase {
  @Inject var repository: IAnalyticsRepository
  @Inject var storeRepository: IStoreRepository
  @Inject var bufferRepository: AnalyticsBufferRepository
  @Inject var persistence: IPersistenceRepository

  func invoke(deviceInformation: DeviceInformation, tags: [String : String], metaData: [String : String]) -> AnyPublisher<Int64, Error> {
    guard let storeId = try? storeRepository.activeStore.statServerConnection.storeId else { return Fail(error: TT2Error.missingData).eraseToAnyPublisher() }
    return repository.createVisit(
      storeId: storeId,
      deviceInformation: deviceInformation,
      tags: tags,
      metaData: metaData
    )
    .handleEvents(receiveOutput: { [weak self] (visitId) in
      guard let object = self?.bufferRepository.startVisit() else { return }
      self?.persistence.save(object.scanEvents, visitId: visitId)
      self?.persistence.save(object.syncEvents, visitId: visitId)
      self?.persistence.save(object.triggerEvents, visitId: visitId)
    })
    .eraseToAnyPublisher()
  }
}

class GetActiveVisitIDUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke() -> Int64? {
    repository.activeVisitId
  }
}

class ResetAnalyticsBufferUseCase {
  @Inject var repository: AnalyticsBufferRepository

  func invoke() {
    repository.reset()
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

class AnalyticsUploadUseCase {
  @Inject var repository: IAnalyticsRepository
  @Inject var persistence: IPersistenceRepository

  func invoke(_ object: UploadScanEvent) {
    repository.upload(visitId: object.visitId, requestId: object.requestId, event: object.event) { [weak self] (error) in
      if let error = error {
        Logger(verbosity: .debug).log(message: "ScanEvent UploadError \(error)")
      } else {
        self?.persistence.delete(object.event)
      }
    }
  }

  func invoke(_ object: UploadSyncEvent) {
    repository.upload(visitId: object.visitId, requestId: object.requestId, event: object.event) { [weak self] (error) in
      if let error = error {
        Logger(verbosity: .debug).log(message: "SyncEvent UploadError \(error)")
      } else {
        self?.persistence.delete(object.event)
      }
    }
  }

  func invoke(_ object: UploadTriggerEvent) {
    repository.upload(visitId: object.visitId, requestId: object.requestId, event: object.event) { [weak self] (error) in
      guard let error = error else {
        self?.persistence.delete(object.event)
        return
      }

      Logger(verbosity: .debug).log(message: "TriggerEvent UploadError \(error) event \(object.event.name)")

      switch error {
      case NetworkError.unprocessable, NetworkError.http(statusCode: 422, data: _):
        // bad/invalid payload — retrying won't fix it, stop trying
        self?.persistence.delete(object.event)
      default:
        // transport error or other server error — keep it, retry later
        break
      }
    }
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
