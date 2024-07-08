//
//  AnalyticsFloorUseCases.swift
//
//
//  Created by Théodore Roos on 2024-06-04.
//

import CoreLocation
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

class UploadDevicePositionUseCase {
  @Inject var analyticsRepository: IAnalyticsRepository
  @Inject var floorRepository: IFloorRepository
  @Inject var storeRepository: IStoreRepository
  @Inject var userRepository: IUserRepository
  let manager = CLLocationManager()

  init() {
    manager.startUpdatingLocation()
  }

  func invoke(signal: VPSOutputSignal.Position, completion: @escaping (Error?) -> ()) {
    analyticsRepository.upload(dpParameters: UploadDevicePostionParameters(
      userId: userRepository.getUserProfile()?.userId ?? "",
      storeId: storeRepository.activeStore.id,
      rtlsOptionsId: floorRepository.activeFloor.id,
      signal: signal, 
      coordinate: manager.location?.coordinate
    ), completion: completion)
  }
}

class UploadGeopositionsForActiveVisitUseCase {
  @Inject var repository: IAnalyticsRepository
  func invoke(geopositions: [String:[RecordedPositionLngLat]], completion: @escaping (Error?) -> ()) {
    guard let id = repository.activeVisitId else { completion(TT2AnalyticsError.visitNotStarted); return }
    repository.upload(visitId: id, geopositions: geopositions, completion: completion)
  }
}

class UploadPositionsForVisitUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke(visitId: Int64, positions: [String:[RecordedPosition]], completion: @escaping (Error?) -> ()) {
    repository.upload(visitId: visitId, positions: positions, completion: completion)
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
