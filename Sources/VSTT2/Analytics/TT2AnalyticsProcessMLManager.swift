//
//  TT2AnalyticsProcessMLManager.swift
//
//
//  Created by Théodore Roos on 2024-08-21.
//

import CoreLocation
import Foundation
import VSFoundation
import VSPositionKit

class TT2AnalyticsProcessMLManager {
  @Inject var positionManager: VPSPositionManager
  var mlPositions: [Int64: [RecordedPositionLngLat]] = [:]
  var currentGPSCoordinate: CLLocationCoordinate2D?

  func update(location: VPSOutputSignal.LatLngPosition, visitId: Int64) -> [Int64: [RecordedPositionLngLat]]? {
    currentGPSCoordinate = location.gpsLocation.coordinate
    switch location.reliableSource {
    case .gps:
      return processMLPath()
    case .undefined:
      break
    case .vpsML:
      let coordinate = location.mlLocation.coordinate
      if mlPositions[visitId] == nil { mlPositions[visitId] = [] }
      mlPositions[visitId]?.append(RecordedPositionLngLat(
        airPressure: positionManager.altimeterPublisher.value?.cmAltitude.pressure.doubleValue,
        timestamp: DateFormatter.standardFormatter.string(from: location.timestamp),
        lngLat: [coordinate.longitude, coordinate.latitude]
      ))
    }
    return nil
  }

  func processMLPath() -> [Int64: [RecordedPositionLngLat]]? {
    let path = mlPositions
    mlPositions.removeAll()
    guard
      path.count > 0,
      let pathEndPoint = currentGPSCoordinate
    else { return nil }
    var processed: [Int64: [RecordedPositionLngLat]] = [:]
    path.forEach { (key, value) in
      guard value.count >= 10 else { return }
      let processedPath = positionManager.processMLPath(
        path: value.map({ CGPoint(x: $0.lngLat[0], y: $0.lngLat[1]) }),
        pathEndPoint: pathEndPoint.asPoint
      ).path.map({ [Double($0.x), Double($0.y)] })
      value.enumerated().forEach {
        if processed[key] == nil { processed[key] = [] }
        processed[key]?.append(RecordedPositionLngLat(
          airPressure: $0.element.airPressure,
          timestamp: $0.element.timestamp,
          lngLat: processedPath[$0.offset]
        ))
      }
    }
    return processed
  }

  func reset() {
    mlPositions.removeAll()
    currentGPSCoordinate = nil
  }
}
