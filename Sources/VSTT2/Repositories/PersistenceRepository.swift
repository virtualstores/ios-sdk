//
//  PersistenceRepository.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-12-01.
//

import Foundation
import VSFoundation

protocol IPersistenceRepository {
  var getScanEvents: [UploadScanEvent] { get }
  var getSyncEvents: [UploadSyncEvent] { get }
  var getTriggerEvents: [UploadTriggerEvent] { get }

  func delete(_ event: ScanEvent)
  func delete(_ event: SyncEvent)
  func delete(_ event: PostTriggerEventRequest)

  func save(_ event: ScanEvent, visitId: Int64)
  func save(_ event: SyncEvent, visitId: Int64)
  func save(_ event: PostTriggerEventRequest, visitId: Int64)

  func save(_ events: [ScanEvent], visitId: Int64)
  func save(_ events: [SyncEvent], visitId: Int64)
  func save(_ events: [PostTriggerEventRequest], visitId: Int64)
}

class PersistenceRepository {
  private let persistence = Persistence()
  private var scanEvents: [UploadScanEventsPersistence] {
    persistence.get(arrayOf: UploadScanEventsPersistence.self)
  }
  private var syncEvents: [UploadSyncEventsPersistence] {
    persistence.get(arrayOf: UploadSyncEventsPersistence.self)
  }

  private var triggerEvents: [UploadTriggerEventPersistence] {
    persistence.get(arrayOf: UploadTriggerEventPersistence.self)
  }
}

extension PersistenceRepository: IPersistenceRepository {
  var getScanEvents: [UploadScanEvent] {
    scanEvents.compactMap {
      guard let id = $0.visitId, let requestId = $0.requestId, let event = $0.asEvent else { return nil }
      return .init(visitId: id, requestId: requestId, event: event)
    }
  }
  
  var getSyncEvents: [UploadSyncEvent] {
    syncEvents.compactMap {
      guard let id = $0.visitId, let requestId = $0.requestId, let event = $0.asEvent else { return nil }
      return .init(visitId: id, requestId: requestId, event: event)
    }
  }

  var getTriggerEvents: [UploadTriggerEvent] {
    triggerEvents.compactMap {
      guard let id = $0.visitId, let requestId = $0.requestId, let event = $0.event else { return nil }
      return .init(visitId: id, requestId: requestId, event: event)
    }
  }

  func delete(_ event: ScanEvent) {
    guard let event = scanEvents.first(where: { $0.timestamp == event.timestamp }) else { return }
    do {
      try persistence.delete(event)
    } catch {
      Logger(verbosity: .error)
        .log(message: "ScanEvent DeleteError \(error)")
    }
  }

  func delete(_ event: SyncEvent) {
    guard let event = syncEvents.first(where: { $0.timestamp == event.timestamp }) else { return }
    do {
      try persistence.delete(event)
    } catch {
      Logger(verbosity: .error)
        .log(message: "SyncEvent DeleteError \(error)")
    }
  }

  func delete(_ event: PostTriggerEventRequest) {
    guard let event = triggerEvents.first(where: { $0.event?.timestamp == event.timestamp }) else { return }
    do {
      try persistence.delete(event)
    } catch {
      Logger(verbosity: .error)
        .log(message: "PostTriggerEventRequest DeleteError \(error)")
    }
  }

  func save(_ event: ScanEvent, visitId: Int64) {
    do {
      var object = event.asPersistence
      object.visitId = visitId
      object.requestId = UUID().uuidString.uppercased()
      try persistence.save(&object)
    } catch {
      Logger(verbosity: .error)
        .log(message: "SyncEvent SaveError \(error)")
    }
  }

  func save(_ event: SyncEvent, visitId: Int64) {
    do {
      var object = event.asPersistence
      object.visitId = visitId
      object.requestId = UUID().uuidString.uppercased()
      try persistence.save(&object)
    } catch {
      Logger(verbosity: .error)
        .log(message: "SyncEvent SaveError \(error)")
    }
  }

  func save(_ event: PostTriggerEventRequest, visitId: Int64) {
    do {
      var object = event.asPersistence
      object.visitId = visitId
      object.requestId = UUID().uuidString.uppercased()
      try persistence.save(&object)
    } catch {
      Logger(verbosity: .error)
        .log(message: "PostTriggerEventRequest SaveError \(error)")
    }
  }

  func save(_ events: [ScanEvent], visitId: Int64) {
    events.forEach { save($0, visitId: visitId) }
  }

  func save(_ events: [SyncEvent], visitId: Int64) {
    events.forEach { save($0, visitId: visitId) }
  }

  func save(_ events: [PostTriggerEventRequest], visitId: Int64) {
    events.forEach { save($0, visitId: visitId) }
  }
}

struct UploadScanEvent {
  let visitId: Int64
  let requestId: String
  let event: ScanEvent
}

struct UploadSyncEvent {
  let visitId: Int64
  let requestId: String
  let event: SyncEvent
}

struct UploadStepEvent {
  let visitId: Int64
  let requestId: String
  let events: [StepEvent]
}

struct UploadTriggerEvent {
  let visitId: Int64
  let requestId: String
  let event: PostTriggerEventRequest
}

class UploadScanEventsPersistence: IPersistenceModel {
  var retainOriginalIndex = false
  var index: String?

  init() {}
  convenience init(index: String) {
    self.init()
    self.index = index
  }

  var visitId: Int64?
  var requestId: String?

  var barcode: String?
  var point: CGPoint?
  var timestamp: String?
  var type: Int?
  var userPosition: CGPoint?
  var floorLevelId: Int64?
  var shelfId: Int64?
  var shelfTierId: Int64?
  var shelfTierPosition: Int64?
  var shelfSectionId: String?
  var sectionPosition: Int?
  var shelfPositionFromLeftToRight: Int?
  var zoneIds: [String]?
}

class UploadTriggerEventPersistence: IPersistenceModel {
  var retainOriginalIndex = false
  var index: String?

  init() {}
  convenience init(index: String) {
    self.init()
    self.index = index
  }

  var visitId: Int64?
  var requestId: String?
  var event: PostTriggerEventRequest?
}

extension ScanEvent {
  var asPersistence: UploadScanEventsPersistence {
    let event = UploadScanEventsPersistence()
    
    event.barcode = barcode
    event.point = point
    event.timestamp = timestamp
    event.type = type.rawValue
    event.userPosition = userPosition
    event.floorLevelId = floorLevelId
    event.shelfId = shelfId
    event.shelfTierId = shelfTierId
    event.shelfTierPosition = shelfTierPosition
    event.shelfSectionId = shelfSectionId
    event.sectionPosition = sectionPosition
    event.shelfPositionFromLeftToRight = shelfPositionFromLeftToRight
    event.zoneIds = zoneIds
    return event
  }
}

extension UploadScanEventsPersistence {
  var asEvent: ScanEvent? {
    guard
      let barcode = barcode,
      let timestamp = timestamp,
      let type = ScanEvent.ShelfType(rawValue: type ?? -1)
    else { return nil }
    return .init(
      barcode: barcode,
      point: point,
      timestamp: timestamp,
      type: type,
      userPosition: userPosition,
      floorLevelId: floorLevelId,
      shelfId: shelfId,
      shelfTierId: shelfTierId,
      shelfTierPosition: shelfTierPosition,
      shelfSectionId: shelfSectionId,
      sectionPosition: sectionPosition,
      shelfPositionFromLeftToRight: shelfPositionFromLeftToRight,
      zoneIds: zoneIds
    )
  }
}

extension SyncEvent {
  var asPersistence: UploadSyncEventsPersistence {
    let event = UploadSyncEventsPersistence()

    event.rtlsOptionsId = self.rtlsOptionsId
    event.identifier = self.identifier
    event.isRightAisle = self.isRightAisle
    event.isFloorSwap = self.isFloorSwap
    event.didSync = self.didSync
    event.rescueModeCountSinceLastSync = self.rescueModeCountSinceLastSync
    event.stepDataDistanceSinceLastSyncInMeters = self.stepDataDistanceSinceLastSyncInMeters
    event.userToSyncPositionDistanceInMeters = self.userToSyncPositionDistanceInMeters
    event.errorAngleInDegrees = self.errorAngleInDegrees
    event.timestamp = self.timestamp
    event.userPositionInMeters = self.userPositionInMeters
    event.syncPositionInMeters = self.syncPositionInMeters
    event.syncPositionOffsetsInMeters = self.syncPositionOffsetsInMeters
    event.tags = self.tags
    return event
  }
}

extension UploadSyncEventsPersistence {
  var asEvent: SyncEvent? {
    guard
      let rtlsOptionsId = rtlsOptionsId,
      let identifier = identifier,
      let isRightAisle = isRightAisle,
      let isFloorSwap = isFloorSwap,
      let didSync = didSync,
      let rescueModeCountSinceLastSync = rescueModeCountSinceLastSync,
      let stepDataDistanceSinceLastSyncInMeters = stepDataDistanceSinceLastSyncInMeters,
      let userToSyncPositionDistanceInMeters = userToSyncPositionDistanceInMeters,
      let errorAngleInDegrees = errorAngleInDegrees,
      let timestamp = timestamp,
      let userPositionInMeters = userPositionInMeters,
      let syncPositionInMeters = syncPositionInMeters,
      let syncPositionOffsetsInMeters = syncPositionOffsetsInMeters,
      let tags = tags
    else { return nil }
    return SyncEvent(
      rtlsOptionsId: rtlsOptionsId,
      identifier: identifier,
      isRightAisle: isRightAisle,
      isFloorSwap: isFloorSwap,
      didSync: didSync,
      rescueModeCountSinceLastSync: rescueModeCountSinceLastSync,
      stepDataDistanceSinceLastSyncInMeters: stepDataDistanceSinceLastSyncInMeters,
      userToSyncPositionDistanceInMeters: userToSyncPositionDistanceInMeters,
      errorAngleInDegrees: errorAngleInDegrees,
      timestamp: timestamp,
      userPositionInMeters: userPositionInMeters,
      syncPositionInMeters: syncPositionInMeters,
      syncPositionOffsetsInMeters: syncPositionOffsetsInMeters,
      tags: tags
    )
  }
}

extension PostTriggerEventRequest {
  var asPersistence: UploadTriggerEventPersistence {
    let object = UploadTriggerEventPersistence()
    object.event = self
    return object
  }
}
