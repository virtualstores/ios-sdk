//
//  TT2AnalyticsGeopositionManager.swift
//
//
//  Created by Théodore Roos on 2024-08-23.
//

import Combine
import CoreLocation
import Foundation
import VSFoundation
import VSPositionKit

class TT2AnalyticsGeopositionManager: Disposable {
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
  private var cancellables: Set<AnyCancellable> = []

  deinit {
    dispose()
  }

  func dispose() {
    cancellables.removeAll()
  }

  var counter = 0
  func update(location: VPSOutputSignal.LatLngPosition) {
    guard let id = visitId else { return }
    if let processedPath = processMlManager.update(location: location, visitId: id) {
      post(processedMLPositions: processedPath)
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
    post(
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
      uploadGeopositions.invoke(visitId: key, geopositions: value)
        .sinkCompletion { (completion) in
          guard case .failure(let error) = completion else { return }
          Logger(verbosity: .error).log(message: "UploadGeopositions - \(key): \(error)")
        }
        .store(in: &cancellables)
    }
    recordedPositionLngLat = [:]
  }

  func stopVisit() {
    postGeopositions()
    if let processedPath = processMlManager.processMLPath() {
      post(processedMLPositions: processedPath)
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
  func upload(
    type: UploadGeoPositionsParameters.TypeEnum,
    visitId: Int64,
    positions: [RecordedPositionLngLat],
    label: String
  ) {
    uploadGeopositions
      .invoke(visitId: visitId, geopositions: [type.rawValue: positions])
      .sinkCompletion { (completion) in
        guard case .failure(let error) = completion else { return }
        Logger(verbosity: .error).log(message: "UploadGeopositions - \(label): \(error)")
      }
      .store(in: &cancellables)
  }

  func post(
    gpsPositions: [Int64: [RecordedPositionLngLat]],
    fullGPSPositions: [Int64: [RecordedPositionLngLat]],
    mlPositions: [Int64: [RecordedPositionLngLat]],
    fullMLPositions: [Int64: [RecordedPositionLngLat]]
  ) {
    gpsPositions.forEach { upload(type: .gps, visitId: $0.key, positions: $0.value, label: "GPS") }
    fullGPSPositions.forEach { upload(type: .fullGPS, visitId: $0.key, positions: $0.value, label: "Full GPS") }
    mlPositions.forEach { upload(type: .vpsMl, visitId: $0.key, positions: $0.value, label: "VPS ML") }
    fullMLPositions.forEach { upload(type: .fullVPSMl, visitId: $0.key, positions: $0.value, label: "Full VPS ML") }
  }

  func post(processedMLPositions: [Int64: [RecordedPositionLngLat]]) {
    processedMLPositions.forEach { upload(type: .vpsMlProcessed, visitId: $0.key, positions: $0.value, label: "VPS ML Processed") }
  }
}
