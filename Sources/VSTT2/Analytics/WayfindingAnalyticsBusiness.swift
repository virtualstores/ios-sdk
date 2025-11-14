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

protocol TrackedItem {
  var identifier: String { get }
}

struct WayfindingItem: TrackedItem {
  let identifier: String
  let position: ItemPosition
}

struct WayfindingZone: TrackedItem {
  let identifier: String
  let position: ZonePosition
}

class WayfindingAnalyticsBusiness {
  @Inject var activeConverter: GetActiveCoordinateConverterUseCase
  @Inject var activeFloor: GetActiveFloorUseCase
  @Inject var activeMapFence: GetActiveMapFenceUseCase
  @Inject var activeStore: GetActiveStoreUseCase
  @Inject var zonesTree: GetZonesTreeUseCase
  private let TAG = "WayfindingAnalyticsBusiness"

  private var isTracking: Bool = false
  private var latestPosition = CGPoint()
  private var latestMLPosition: CGPoint?
  private var trackedItem: TrackedItem?
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

  func startTracking(item: TrackedItem) -> TriggerEvent? {
    var abortedTriggerEvent: TriggerEvent?
    if let event = trackedItem {
//      TT2Log.d("$TAG.startTracking: already tracking, stopping and tracking new one")
      abortedTriggerEvent = stopTracking(identifier: event.identifier, stopType: .abort)
    }

//    TT2Log.d("$TAG.startTracking: ${itemPosition.identifier}")

    guard let mapFence = try? activeMapFence.invoke() else { return abortedTriggerEvent }
    if let item = item as? WayfindingItem {
      inAndOut = .init(triggers: [
        InAndOut.Radius(id: item.position.identifier, centerPoint: item.position.pointWithOffset, radius: rangeThreshold)
      ])
    } else if let item = item as? WayfindingZone {
      guard let zone = try? zonesTree.invoke().getZonesForCurrentFloorLevel()?.first(where: { $0.id == item.position.id }) else { return abortedTriggerEvent}
      inAndOut = .init(triggers: [
        InAndOut.Zone(id: item.position.id, zoneId: item.position.id, polygon: zone.points)
      ])
    }

    inAndOut?.delegate = self

    latestPosition = CGPoint()
    latestMLPosition = nil
    trackedItem = item
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
          if let item = trackedItem as? WayfindingItem {
            checkIsRightAisle(userLocation: position.point, itemLocation: item.position.pointWithOffset)
            checkDistanceToItem(userLocation: position.point, itemLocation: item.position.pointWithOffset)
          } else if let item = trackedItem as? WayfindingZone {
            checkDistanceToItem(userLocation: position.point, itemLocation: item.position.point)
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
          } else if let item = trackedItem as? WayfindingItem {
            distanceToItem = item.position.pointWithOffset.distance(to: mlPosition.point)
          } else if let item = trackedItem as? WayfindingZone {
            distanceToItem = item.position.point.distance(to: mlPosition.point)
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

  func stopTracking(identifier: String, stopType: StopType = .normal) -> TriggerEvent? {
    guard let id = try? activeFloor.invoke().id else { return nil }
    isTracking = false

//    TT2Log.d("$TAG.stopTracking: ${itemPosition.identifier}: HasBeenRightAisle=$hasBeenInRightAisle, HasBeenInRange=$hasBeenInRange")
    var triggerEvent: TriggerEvent?
    if let trackedItem = trackedItem, trackedItem.identifier == identifier, let timestamp = startTimestamp {
      var zoneId: String?
      if let item = trackedItem as? WayfindingZone {
        zoneId = item.position.name
      }
      triggerEvent = TriggerEvent(
        rtlsOptionsId: id,
        name: "single-item-wayfinding",
        description: "",
        eventType: .appTrigger(.init(event: "single-item-wayfinding")),
        tags: createStopEventTags(startTimestamp: timestamp, identifier: identifier, stopType: stopType, zoneId: zoneId)
      )
    }

    latestPosition = CGPoint()
    latestMLPosition = nil
    trackedItem = nil
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

  private func createStopEventTags(startTimestamp: Date, identifier: String, stopType: StopType, zoneId: String?) -> [String: String] {
    var tags = [
      "startTimestamp": DateFormatter.standardFormatter.string(from: startTimestamp),
      "stopTimestamp": DateFormatter.standardFormatter.string(from: .init()),
      "identifier": identifier,
      "hasBeenInRange": hasBeenInRange.description,
      "hasBeenInRightAisle": hasBeenInRightAisle.description,
      "stopType": stopType.rawValue,
      "isValidDistance": (isValidDistance || hasBeenInRightAisle).description,
      "distanceTraveled": distanceTraveled.description
    ]

    if let distance = shortestDistanceToItem {
      tags["shortestDistance"] = distance.description
    }

    if let id = zoneId {
      tags["zoneId"] = id
    }

    return tags
  }

  func stopVisit() -> TriggerEvent? {
    guard let item = trackedItem else { return nil }
    return stopTracking(identifier: item.identifier, stopType: .stopVisit)
  }
}

extension WayfindingAnalyticsBusiness: IInAndOutDelegate {
  func onEnter(trigger: IInAndOutTrigger, position: CGPoint) {
    guard
      let item = trackedItem,
      item.identifier == trigger.id
    else { return }
    if item is WayfindingItem {
      hasBeenInRange = true
    } else if item is WayfindingZone {
      hasBeenInRange = true
      hasBeenInRightAisle = true
    }
    isInRange = true
  }
  
  func onExit(trigger: IInAndOutTrigger, position: CGPoint) {
    guard
      let item = trackedItem,
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
