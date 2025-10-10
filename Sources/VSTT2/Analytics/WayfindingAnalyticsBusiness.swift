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

class WayfindingAnalyticsBusiness {
  @Inject var activeConverter: GetActiveCoordinateConverterUseCase
  @Inject var activeFloor: GetActiveFloorUseCase
  @Inject var activeMapFence: GetActiveMapFenceUseCase
  @Inject var activeStore: GetActiveStoreUseCase
  private let TAG = "WayfindingAnalyticsBusiness"

  private var isTracking: Bool = false
  private var latestPosition = CGPoint()
  private var latestMLPosition: CGPoint?
  private var trackedItemPosition: ItemPosition?
  private var startTimestamp: Date?
  private var hasBeenInRange: Bool = false
  private var isInRange: Bool = false
  private var hasBeenInRightAisle: Bool = false
  private var positionCounter: Int = 0
  private var mlPositionCounter: Int = 0
  private var inAndOut: InAndOut?
  private var mapFenceData: MapFenceData?
  private var isValidDistance: Bool = false
  private var shortestDistanceToItem: Double?
  private var distanceTraveled: Double = 0.0
  private var distanceToItem: Double?

  private var positionServiceSettings: PositionServiceSettings? { try? activeStore.invoke().positionServiceSettings }
  private var rangeThreshold: Double {
    positionServiceSettings?.floatValues?["ios_sdk_analytics_wayfindingRangeThreshold"]?.asDouble ?? 10
  }
  private var distanceThreshold: Double {
    guard let threshold = positionServiceSettings?.floatValues?["ios_sdk_analytics_wayfindingDistanceThreshold"]?.asDouble else { return 0.70 }
    return threshold.coerceIn(0.0, 1.0)
  }

  enum StopType: String {
    case normal = "NORMAL"
    case abort = "ABORT"
    case stopVisit = "STOP_VISIT"
  }

  func startTracking(itemPosition: ItemPosition) -> TriggerEvent? {
    var abortedTriggerEvent: TriggerEvent?
    if let event = trackedItemPosition {
//      TT2Log.d("$TAG.startTracking: already tracking, stopping and tracking new one")
      abortedTriggerEvent = stopTracking(itemPosition: event, stopType: .abort)
    }

//    TT2Log.d("$TAG.startTracking: ${itemPosition.identifier}")

    guard let mapFence = try? activeMapFence.invoke() else { return abortedTriggerEvent }
    inAndOut = .init(triggers: [
      InAndOut.Radius(id: itemPosition.identifier, centerPoint: itemPosition.pointWithOffset, radius: rangeThreshold)
    ])
    inAndOut?.delegate = self

    latestPosition = CGPoint()
    latestMLPosition = nil
    trackedItemPosition = itemPosition
    startTimestamp = .init()
    hasBeenInRange = false
    hasBeenInRightAisle = false
    distanceToItem = nil
    distanceTraveled = 0
    isValidDistance = false
    positionCounter = 0
    mlPositionCounter = 0
    shortestDistanceToItem = nil
    isInRange = false
    isTracking = true
    mapFenceData = MapFenceFactory.getMapFenceData(fromMapFence: mapFence)
    return abortedTriggerEvent
  }

  func onNew(position: VPSOutputSignal.Position) {
    if isTracking {
      positionCounter += 1
      if positionCounter >= 3 {
        if position.point != latestPosition {
          positionCounter = 0
          latestPosition = position.point

          inAndOut?.on(new: position.point)
          if let itemPosition = trackedItemPosition {
            checkIsRightAisle(userLocation: position.point, itemLocation: itemPosition.pointWithOffset)
            checkDistanceToItem(userLocation: position.point, itemLocation: itemPosition.pointWithOffset)
          }
        }
      }
    }
  }

  func onNew(mlPosition: VPSOutputSignal.Position) {
    if isTracking {
      mlPositionCounter += 1
      if mlPositionCounter >= 3 {
        if mlPosition.point != latestMLPosition {
          mlPositionCounter = 0
          distanceTraveled += latestMLPosition?.distance(to: mlPosition.point) ?? 0.0
          latestMLPosition = mlPosition.point

          if let distance = distanceToItem {
            checkDistanceTraveled(distanceTraveled: distanceTraveled, distanceToItem: distance)
          } else if let itemPosition = trackedItemPosition {
            distanceToItem = itemPosition.pointWithOffset.distance(to: mlPosition.point)
          }
        }
      }
    }
  }

  private func checkIsRightAisle(userLocation: CGPoint, itemLocation: CGPoint) {
    guard
      isInRange,
      !hasBeenInRightAisle,
      let converter = try? activeConverter.invoke(),
      let isRightAisle = mapFenceData?.isRightAisle(
        p1: userLocation.fromMeterToPixel(converter: converter).flipY(converter: converter),
        p2: itemLocation.fromMeterToPixel(converter: converter).flipY(converter: converter)
      )
    else { return }
    if !hasBeenInRightAisle {
      hasBeenInRightAisle = isRightAisle
//      TT2Log.d("$TAG.checkIsRightAisle: Has been in right aisle")
    }
  }

  private func checkDistanceToItem(userLocation: CGPoint, itemLocation: CGPoint) {
    guard let shortestDistance = shortestDistanceToItem else {
      shortestDistanceToItem = userLocation.distance(to: itemLocation)
      return
    }
    let distance = userLocation.distance(to: itemLocation)
    if distance < shortestDistance {
      shortestDistanceToItem = distance
    }
  }

  private func checkDistanceTraveled(distanceTraveled: Double, distanceToItem: Double) {
    let isValid = isAboveThreshold(a: distanceTraveled, b: distanceToItem, threshold: 0.7)
    guard isValid else { return }
    if !isValidDistance {
      isValidDistance = isValid
    }
  }

  private func isAboveThreshold(a: Double, b: Double, threshold: Double) -> Bool {
    a >= b * threshold
  }

  func stopTracking(itemPosition: ItemPosition, stopType: StopType = .normal) -> TriggerEvent? {
    guard let id = try? activeFloor.invoke().id else { return nil }
    isTracking = false

//    TT2Log.d("$TAG.stopTracking: ${itemPosition.identifier}: HasBeenRightAisle=$hasBeenInRightAisle, HasBeenInRange=$hasBeenInRange")
    var triggerEvent: TriggerEvent?
    if let position = trackedItemPosition, position.identifier == itemPosition.identifier, let timestamp = startTimestamp {
      triggerEvent = TriggerEvent(
        rtlsOptionsId: id,
        name: "single-item-wayfinding",
        description: "",
        eventType: .appTrigger(.init(event: "single-item-wayfinding")),
        tags: createStopEventTags(startTimestamp: timestamp, position: position, stopType: stopType)
      )
    }

    latestPosition = CGPoint()
    latestMLPosition = nil
    trackedItemPosition = nil
    startTimestamp = nil
    hasBeenInRange = false
    hasBeenInRightAisle = false
    distanceToItem = nil
    isValidDistance = false
    shortestDistanceToItem = nil
    isInRange = false
    positionCounter = 0
    mlPositionCounter = 0
    distanceTraveled = 0
    inAndOut?.reset()
    inAndOut?.delegate = nil
    inAndOut = nil
    mapFenceData = nil

    return triggerEvent
  }

  private func createStopEventTags(startTimestamp: Date, position: ItemPosition, stopType: StopType) -> [String: String] {
    var tags = [
      "startTimestamp": DateFormatter.standardFormatter.string(from: startTimestamp),
      "stopTimestamp": DateFormatter.standardFormatter.string(from: .init()),
      "identifier": position.identifier,
      "hasBeenInRange": hasBeenInRange.description,
      "hasBeenInRightAisle": hasBeenInRightAisle.description,
      "stopType": stopType.rawValue,
      "isValidDistance": (isValidDistance || hasBeenInRightAisle).description,
      "distanceTraveled": distanceTraveled.description
    ]

    if let distance = shortestDistanceToItem {
      tags["shortestDistance"] = distance.description
    }

    return tags
  }

  func stopVisit() -> TriggerEvent? {
    guard let trackedItemPosition = trackedItemPosition else { return nil }
    return stopTracking(itemPosition: trackedItemPosition, stopType: .stopVisit)
  }
}

extension WayfindingAnalyticsBusiness: IInAndOutDelegate {
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
