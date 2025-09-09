//
//  WayfindingAnalyticsBusiness.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-09-08.
//

import Foundation
import CoreGraphics
import VSFoundation
import VSPositionKit

class WayFindingAnalyticsBusiness {
  @Inject var activeConverter: GetActiveCoordinateConverterUseCase
  @Inject var activeFloor: GetActiveFloorUseCase
  @Inject var activeMapFence: GetActiveMapFenceUseCase
  private let TAG = "WayFindingAnalyticsBusiness"

  private let rangeThreshold: Double

  private var isTracking: Bool = false
  private var latestPosition = CGPoint()
  private var trackedItemPosition: ItemPosition?
  private var startTimestamp: Date?
  private var hasBeenInRange: Bool = false
  private var isInRange: Bool = false
  private var hasBeenInRightAisle: Bool = false
  private var counter: Int = 0
  private var inAndOut: InAndOut?
  private var mapFenceData: MapFenceData?

  enum StopType: String {
    case normal = "NORMAL"
    case abort = "ABORT"
    case stopVisit = "STOP_VISIT"
  }

  init(rangeThreshold: Double? = nil) {
    self.rangeThreshold = rangeThreshold ?? 10
  }

  func startTracking(itemPosition: ItemPosition) -> TriggerEvent? {
    var abortedTriggerEvent: TriggerEvent?
    if let event = trackedItemPosition {
//      TT2Log.d("$TAG.startTracking: already tracking, stopping and tracking new one")
      abortedTriggerEvent = stopTracking(itemPosition: event, stopType: .abort)
    }

//    TT2Log.d("$TAG.startTracking: ${itemPosition.identifier}")

    guard let mapFence = activeMapFence.invoke() else { return abortedTriggerEvent }
    inAndOut = .init(triggers: [
      InAndOut.Radius(id: itemPosition.identifier, centerPoint: itemPosition.pointWithOffset, radius: rangeThreshold)
    ])
    inAndOut?.delegate = self

    trackedItemPosition = itemPosition
    startTimestamp = .init()
    hasBeenInRange = false
    hasBeenInRightAisle = false
    isInRange = false
    isTracking = true
    mapFenceData = MapFenceFactory.getMapFenceData(fromMapFence: mapFence)
    return abortedTriggerEvent
  }

  func onNewPosition(position: VPSOutputSignal.Position) {
    if (isTracking) {
      counter += 1
      if (counter >= 3) {
        if (position.point != latestPosition) {
          counter = 0
          latestPosition = position.point

          inAndOut?.on(new: position.point)
          if let itemPosition = trackedItemPosition {
            checkIsRightAisle(userLocation: position.point, itemLocation: itemPosition.pointWithOffset)
          }
        }
      }
    }
  }

  private func checkIsRightAisle(userLocation: CGPoint, itemLocation: CGPoint) {
    guard
      isInRange,
      !hasBeenInRightAisle,
      let converter = activeConverter.invoke(),
      let isRightAisle = mapFenceData?.isRightAisle(
        p1: userLocation.fromMeterToPixel(converter: converter).flipY(converter: converter),
        p2: itemLocation.fromMeterToPixel(converter: converter).flipY(converter: converter)
      )
    else { return }
    if (!hasBeenInRightAisle) {
      hasBeenInRightAisle = isRightAisle
//      TT2Log.d("$TAG.checkIsRightAisle: Has been in right aisle")
    }
  }

  func stopTracking(itemPosition: ItemPosition, stopType: StopType = .normal) -> TriggerEvent? {
    isTracking = false

//    TT2Log.d("$TAG.stopTracking: ${itemPosition.identifier}: HasBeenRightAisle=$hasBeenInRightAisle, HasBeenInRange=$hasBeenInRange")
    var triggerEvent: TriggerEvent?
    if let position = trackedItemPosition, position.identifier == itemPosition.identifier, let timestamp = startTimestamp {
      triggerEvent = TriggerEvent(
        rtlsOptionsId: activeFloor.invoke().id,
        name: "single-item-wayfinding",
        description: "",
        eventType: .appTrigger(.init(event: "single-item-wayfinding")),
        tags: [
          "startTimestamp": DateFormatter.standardFormatter.string(from: timestamp),
          "stopTimestamp": DateFormatter.standardFormatter.string(from: .init()),
          "identifier": position.identifier,
          "hasBeenInRange": hasBeenInRange.description,
          "hasBeenInRightAisle": hasBeenInRightAisle.description,
          "stopType": stopType.rawValue
        ]
      )
    }

    latestPosition = CGPoint()
    trackedItemPosition = nil
    startTimestamp = nil
    hasBeenInRange = false
    hasBeenInRightAisle = false
    isInRange = false
    counter = 0
    inAndOut?.reset()
    inAndOut?.delegate = nil
    inAndOut = nil
    mapFenceData = nil

    return triggerEvent
  }

  func stopVisit() -> TriggerEvent? {
    guard let trackedItemPosition = trackedItemPosition else { return nil }
    return stopTracking(itemPosition: trackedItemPosition, stopType: .stopVisit)
  }
}

extension WayFindingAnalyticsBusiness: IInAndOutDelegate {
  func onEnter(trigger: IInAndOutTrigger, position: CGPoint) {
    guard
      let item = trackedItemPosition,
      item.identifier == trigger.id
    else { return }
    hasBeenInRange = true
    isInRange = true
  }
  
  func onExit(trigger: IInAndOutTrigger, position: CGPoint) {
    guard
      let item = trackedItemPosition,
      item.identifier == trigger.id
    else { return }
    isInRange = false
  }
  
  func onEnter(triggers: [IInAndOutTrigger], position: CGPoint) {
    triggers.forEach { onEnter(trigger: $0, position: position) }
  }
  
  func onExit(triggers: [IInAndOutTrigger], position: CGPoint) {
    triggers.forEach { onExit(trigger: $0, position: position) }
  }
}
