//
//  TT2AnalyticsGeopositionManager.swift
//
//
//  Created by Théodore Roos on 2024-08-23.
//

import CoreLocation
import Foundation
import VSFoundation
import VSPositionKit

class TT2AnalyticsGeopositionManager {
  @Inject var positionManager: VPSPositionManager
  @Inject var activeVisitId: GetActiveVisitIDUseCase
  @Inject var uploadGeopositions: UploadGeopositionsForVisitUseCase
  @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
  private let processMlManager: TT2AnalyticsProcessMLManager = .init()

  private var visitId: Int64? { activeVisitId.invoke() }
  private var airPressure: Double? { positionManager.altimeterPublisher.value?.cmAltitude.pressure.doubleValue }
  private var recordedGPSPositionsLngLat: [Int64: [RecordedPositionLngLat]] = [:]
  private var recordedFullGPSPositionsLngLat: [Int64: [RecordedPositionLngLat]] = [:]
  private var recordedMLPositionsLngLat: [Int64: [RecordedPositionLngLat]] = [:]
  private var recordedFullMLPositionsLngLat: [Int64: [RecordedPositionLngLat]] = [:]
  private var recordedPositionLngLat: [Int64: [String: [RecordedPositionLngLat]]] = [:]

  var counter = 0
  func update(location: VPSOutputSignal.LatLngPosition) {
    guard let id = visitId else { return }
    if let processedPath = processMlManager.update(location: location, visitId: id) {
      postProcessedPath(processedMLPositions: processedPath)
    }
    let gpsCoordinate = location.gpsLocation.coordinate
    let mlCoordinate = location.mlLocation.coordinate
    let gpsPosition = RecordedPositionLngLat(
      airPressure: airPressure,
      timestamp: DateFormatter.standardFormatter.string(from: location.timestamp),
      lngLat: [gpsCoordinate.longitude, gpsCoordinate.latitude]
    )
    let mlPosition = RecordedPositionLngLat(
      airPressure: airPressure,
      timestamp: DateFormatter.standardFormatter.string(from: location.timestamp),
      lngLat: [mlCoordinate.longitude, mlCoordinate.latitude]
    )

    switch getTT2Settings.invoke().engine {
    case .openTerrain:
      saveGeoposition(type: .gps, id: id, position: gpsPosition)
      saveGeoposition(type: .vpsMl, id: id, position: mlPosition)
    default:
      switch location.reliableSource {
      case .gps:
        saveGeoposition(type: .gps, id: id, position: gpsPosition)
      case .undefined: break
      case .vpsML:
        saveGeoposition(type: .vpsMl, id: id, position: mlPosition)
      }
    }

    saveGeoposition(type: .fullGPS, id: id, position: gpsPosition)
    saveGeoposition(type: .fullVPSMl, id: id, position: mlPosition)

    counter += 1
    if counter >= 100 {
      counter = 0
      postGeopositions()
    }
  }

  func saveGeoposition(type: UploadGeoPositionsParameters.TypeEnum, id: Int64, position: RecordedPositionLngLat) {
    switch type {
    case .gps:
      if recordedGPSPositionsLngLat[id] == nil { recordedGPSPositionsLngLat[id] = [] }
      recordedGPSPositionsLngLat[id]?.append(position)
    case .fullGPS:
      if recordedFullGPSPositionsLngLat[id] == nil { recordedFullGPSPositionsLngLat[id] = [] }
      recordedFullGPSPositionsLngLat[id]?.append(position)
    case .vpsMl:
      if recordedMLPositionsLngLat[id] == nil { recordedMLPositionsLngLat[id] = [] }
      recordedMLPositionsLngLat[id]?.append(position)
    case .fullVPSMl:
      if recordedFullMLPositionsLngLat[id] == nil { recordedFullMLPositionsLngLat[id] = [] }
      recordedFullMLPositionsLngLat[id]?.append(position)
    case .vpsMlProcessed: break
    }
  }

  func postGeopositions() {
    let gpsPositions = recordedGPSPositionsLngLat
    let fullGPSPositions = recordedFullGPSPositionsLngLat
    let mlPositions = recordedMLPositionsLngLat
    let fullMLPositions = recordedFullMLPositionsLngLat
    postGeopositions(
      gpsPositions: gpsPositions,
      fullGPSPositions: fullGPSPositions,
      mlPositions: mlPositions,
      fullMLPositions: fullMLPositions
    )

    recordedGPSPositionsLngLat = [:]
    recordedFullGPSPositionsLngLat = [:]
    recordedMLPositionsLngLat = [:]
    recordedFullMLPositionsLngLat = [:]

    let positions = recordedPositionLngLat
    positions.forEach { (key, value) in
      uploadGeopositions.invoke(visitId: key, geopositions: value) { (error) in
        if let error = error {
          Logger(verbosity: .error).log(message: "UploadGeopositions - \(key): \(error)")
        }
      }
    }
    recordedPositionLngLat = [:]
  }

  func stopVisit() {
    postGeopositions()
    if let processedPath = processMlManager.processMLPath() {
      postProcessedPath(processedMLPositions: processedPath)
    }
    processMlManager.reset()
    counter = 0
  }

  func record(coordinate: CLLocationCoordinate2D, for tag: String) {
    guard let id = visitId else { return }
    if recordedPositionLngLat[id] == nil { recordedPositionLngLat[id] = [:] }
    if recordedPositionLngLat[id]?[tag] == nil { recordedPositionLngLat[id]?[tag] = [] }
    recordedPositionLngLat[id]?[tag]?.append(RecordedPositionLngLat(
      airPressure: airPressure,
      timestamp: DateFormatter.standardFormatter.string(from: Date()),
      lngLat: [coordinate.longitude, coordinate.latitude]
    ))
  }
}

private extension TT2AnalyticsGeopositionManager {
  func postGeopositions(
    gpsPositions: [Int64: [RecordedPositionLngLat]],
    fullGPSPositions: [Int64: [RecordedPositionLngLat]],
    mlPositions: [Int64: [RecordedPositionLngLat]],
    fullMLPositions: [Int64: [RecordedPositionLngLat]]
  ) {
    gpsPositions.forEach { (key, value) in
      uploadGeopositions.invoke(visitId: key, geopositions: [UploadGeoPositionsParameters.TypeEnum.gps.rawValue : value]) { (error) in
        if let error = error {
          Logger(verbosity: .error).log(message: "UploadGeopositions - GPS: \(error)")
        }
      }
    }

    fullGPSPositions.forEach { (key, value) in
      uploadGeopositions.invoke(visitId: key, geopositions: [UploadGeoPositionsParameters.TypeEnum.fullGPS.rawValue : value]) { (error) in
        if let error = error {
          Logger(verbosity: .error).log(message: "UploadGeopositions - Full GPS: \(error)")
        }
      }
    }

    mlPositions.forEach { (key, value) in
      uploadGeopositions.invoke(visitId: key, geopositions: [UploadGeoPositionsParameters.TypeEnum.vpsMl.rawValue : value]) { (error) in
        if let error = error {
          Logger(verbosity: .error).log(message: "UploadGeopositions - VPS ML: \(error)")
        }
      }
    }

    fullMLPositions.forEach { (key, value) in
      uploadGeopositions.invoke(visitId: key, geopositions: [UploadGeoPositionsParameters.TypeEnum.fullVPSMl.rawValue : value]) { (error) in
        if let error = error {
          Logger(verbosity: .error).log(message: "UploadGeopositions - Full VPS ML: \(error)")
        }
      }
    }
  }

  func postProcessedPath(processedMLPositions: [Int64: [RecordedPositionLngLat]]) {
    processedMLPositions.forEach { (key, value) in
      uploadGeopositions.invoke(visitId: key, geopositions: [UploadGeoPositionsParameters.TypeEnum.vpsMlProcessed.rawValue : value]) { (error) in
        if let error = error {
          Logger(verbosity: .error).log(message: "UploadGeopositions - VPS ML Processed: \(error)")
        }
      }
    }
  }
}

final class TT2GeopositionUploadWorker {
  @Inject var persistence: Persistence
  var positionObjects: [RecordedPositionLngLatDTO] { persistence.get(arrayOf: RecordedPositionLngLatDTO.self) }

  func insert(visitId: Int64, position: RecordedPositionLngLat) {
    var object = RecordedPositionLngLatDTO()
    object.airPressure = position.airPressure
    object.timestamp = position.timestamp
    object.lngLat = position.lngLat
    object.visitId = visitId
    object.status = PointStatus.inProgress.rawValue

    do {
      try persistence.save(&object)
    } catch {
      Logger(verbosity: .error).log(message: "Failed to save geoposition: \(error)")
    }
  }

  func get() -> [RecordedPositionLngLatDTO] {
    var positions = positionObjects
      .filter { $0.status == PointStatus.pending.rawValue || $0.status == PointStatus.fail.rawValue }
    updateObjectStatus(positions, status: .inProgress)
    return positions
  }

  func removeCompleted() {
    var positions = positionObjects
      .filter { $0.status == PointStatus.complete.rawValue }
    positions.forEach { (object) in
      do {
        try persistence.delete(object)
      } catch {
        Logger(verbosity: .error).log(message: "Failed to delete geoposition: \(error)")
      }
    }
  }

  func update(uploadSucceded: Bool) {
    var positions = positionObjects
      .filter { $0.status == PointStatus.inProgress.rawValue }
    updateObjectStatus(positions, status: uploadSucceded ? .complete : .fail)
  }

  private func updateObjectStatus(_ objects: [RecordedPositionLngLatDTO], status: PointStatus) {
    objects.forEach { (object) in
      var editedObject = object
      editedObject.status = status.rawValue

      do {
        try persistence.save(&editedObject)
      } catch {
        Logger(verbosity: .error).log(message: "Failed to update geoposition status: \(error)")
      }
    }
  }
}
