//
//  PersistenceUseCases.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-12-03.
//

import VSFoundation

class GetScanEventsUseCase {
  @Inject var repository: IPersistenceRepository

  func invoke() -> [UploadScanEvent] {
    repository.getScanEvents
  }
}

class GetSyncEventsUseCase {
  @Inject var repository: IPersistenceRepository

  func invoke() -> [UploadSyncEvent] {
    repository.getSyncEvents
  }
}

class GetTriggerEventsUseCase {
  @Inject var repository: IPersistenceRepository

  func invoke() -> [UploadTriggerEvent] {
    repository.getTriggerEvents
  }
}

class DeleteEventUseCase {
  @Inject var repository: IPersistenceRepository
  @Inject var analyticsRepository: IAnalyticsRepository

  func invoke(event: SyncEvent) {
    repository.delete(event)
  }

  func invoke(event: PostTriggerEventRequest) {
    repository.delete(event)
  }
}

class SaveEventUseCase {
  @Inject var repository: IPersistenceRepository
  @Inject var analyticsRepository: IAnalyticsRepository

  func invoke(event: SyncEvent) {
    guard let id = analyticsRepository.activeVisitId else { return }
    repository.save(event, visitId: id)
  }

  func invoke(event: PostTriggerEventRequest) {
    guard let id = analyticsRepository.activeVisitId else { return }
    repository.save(event, visitId: id)
  }
}
