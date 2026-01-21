//
//  AccuracyUploader.swift
//  
//
//  Created by Théodore Roos on 2022-03-22.
//

import Combine
import Foundation
import UIKit
import VSFoundation
import VSPositionKit

class AccuracyUploader {
  @Inject var analytics: TT2AnalyticsManager
  @Inject var config: EnvironmentConfig

  @Inject var getActiveClient: GetActiveClientUseCase
  @Inject var getActiveMapFence: GetActiveMapFenceUseCase
  @Inject var getActiveStore: GetActiveStoreUseCase
  @Inject var getActiveVisitId: GetActiveVisitIDUseCase
  @Inject var activeFloor: GetActiveFloorUseCase
  @Inject var bufferOrPersist: BufferOrPersistEventForActiveVisitUseCase

  @Inject var converter: GetActiveCoordinateConverterUseCase

  @Inject var getVPSPosition: GetCurrentVPSPositionUseCase

  @Inject var getEvents: GetSyncEventsUseCase

  var stepEventUploader: StepEventUploader? { analytics.stepEventUploader }

  var numberOfRescueModes: Int64 = 0

  enum Errors: Error {
    case uploadFailure(HTTPURLResponse)
  }

  func upload(syncEvent: AccuracySyncEvent.Event, isFloorSwap: Bool) {
    guard
      let rtlsOptionsId = try? activeFloor.invoke().id,
      let mapFence = try? getActiveMapFence.invoke(),
      let converter = try? converter.invoke(),
      let stepEventUploader = stepEventUploader
    else { return }
    let mapFenceData = MapFenceFactory.getMapFenceData(fromMapFence: mapFence)
    let identifier: String
    var didSync: Bool = true
    var point: CGPoint = .zero
    var pointWithOffset: CGPoint = .zero
    var preScanLocation: CGPoint? = getVPSPosition.invoke()?.point
    var offset: CGVector?
    var tags:[String:String]

    switch syncEvent {
    case .syncEvent(let event):
      let position = event.itemPosition
      identifier = position.identifier
      point = position.point
      pointWithOffset = position.pointWithOffset
      preScanLocation = event.preSyncScanLocation
      offset = position.offset
      didSync = event.didSync
      tags = [
        "identifier": identifier,
        "isStartSync": String(false)
      ]
      if let shelfId = position.shelfId {
        tags["shelfId"] = String(shelfId)
      }
    case .syncEventMissingPosition(let event):
      identifier = event.identifier
      didSync = false
      tags = [
        "identifier": identifier,
        "isStartSync": String(false),
        "noItemPosition": String(true)
      ]
    case .syncEventMultipleItemPosition(let event):
      identifier = event.item.externalId
      didSync = false
      tags = [
        "identifier": identifier,
        "isStartSync": String(false),
        "multipleItemPosition": String(true)
      ]
    case .startLocationSyncEvent(let event):
      identifier = event.startScanLocation.code
      point = event.startScanLocation.point
      pointWithOffset = point
      tags = [
        "identifier": identifier,
        "isStartSync": String(true),
        "syncAngle": String(event.startScanLocation.direction)
      ]
    case .startSyncEvent(let event):
      let position = event.itemPosition
      identifier = position.identifier
      point = position.point
      pointWithOffset = position.pointWithOffset
      offset = position.offset
      didSync = event.didSync
      tags = [
        "identifier": identifier,
        "isStartSync": String(true),
        "syncAngle": String(event.startDirection)
      ]
      if let shelfId = position.shelfId {
        tags["shelfId"] = String(shelfId)
      }
    }

    let preScanLocationInPixels = preScanLocation?.fromMeterToPixel(converter: converter).flipY(converter: converter)
    let scanLocationInPixels = pointWithOffset.fromMeterToPixel(converter: converter).flipY(converter: converter)
    let isRightAisle = preScanLocation != nil ? mapFenceData.isRightAisle(p1: preScanLocationInPixels!, p2: scanLocationInPixels) : false

    //tags["isWifiResetSync"] = String(false)
    //if (tags["isWifiResetSync"]! as NSString).boolValue {
    //  tags["wifiResetSyncRadius"] = String(0)
    //}
    let distance = stepEventUploader.events.map { $0.distance }.sum()
    let event = SyncEvent(
      rtlsOptionsId: rtlsOptionsId,
      identifier: identifier,
      isRightAisle: !isFloorSwap ? isRightAisle : false,
      isFloorSwap: isFloorSwap,
      didSync: didSync,
      rescueModeCountSinceLastSync: numberOfRescueModes,
      stepDataDistanceSinceLastSyncInMeters: distance,
      userToSyncPositionDistanceInMeters: (preScanLocation ?? point).distance(to: point),
      errorAngleInDegrees: 0,
      timestamp: .dateWithStandardFormatter(.init()),
      userPositionInMeters: preScanLocation ?? .zero,
      syncPositionInMeters: point,
      syncPositionOffsetsInMeters: offset ?? .zero,
      tags: tags
    )
    numberOfRescueModes = 0
    bufferOrPersist.invoke(event: event)
    stepEventUploader.upload()
  }
}

struct AccuracySyncEvent {
  enum Event {
    case syncEvent(SyncEvent)
    case syncEventMissingPosition(SyncEventMissingPosition)
    case syncEventMultipleItemPosition(SyncEventMultipleItemPosition)
    case startLocationSyncEvent(StartLocationSyncEvent)
    case startSyncEvent(StartSyncEvent)
  }

  struct SyncEvent {
    let itemPosition: ItemPosition
    let preSyncScanLocation: CGPoint
    let didSync: Bool
  }
  struct SyncEventMissingPosition {
    let identifier: String
  }
  struct SyncEventMultipleItemPosition {
    let item: Item
  }
  struct StartLocationSyncEvent {
    let startScanLocation: PositionedCode
  }
  struct StartSyncEvent {
    let itemPosition: ItemPosition
    let startDirection: Double
    let didSync: Bool
  }
}
