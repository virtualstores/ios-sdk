// SaveAnalyticsToFileUseCase.swift
// VSTT2

// Created by: CJ on 2025-04-25
// Copyright (c) 2025

import Foundation
import VSFoundation

class CreateOfflineVisitDirectoryUseCase {
  @Inject var repository: IAnalyticsRepository
  @Inject var statusRepository: IStatusRepository

  func invoke() {
    guard
      statusRepository.currentSettings.saveToDiskEnabled,
      let visitId = repository.activeVisitId,
      let directoryURL = CreateOfflineVisitDirectoryBusiness().invoke(visitId: visitId, sessionId: repository.activeSessionId, timestamp: DateFormatter.standardFormatter.string(from: Date()))
    else { return }
    repository.setDirectoryURL(visitId: visitId, url: directoryURL)
  }
}

class CreateOfflineVisitDirectoryBusiness {
  func invoke(visitId: Int64, sessionId: Int, timestamp: String) -> URL? {
    // Create a directory: 2025-04-25T10-50-34_visitId_sessionId
    // Set directory in repoisitory
    var directoryURL: URL?
    do {
      let documentDirectory = try FileManager.default.createRootDirectory
      let normalizedTimestamp = timestamp.replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: ".", with: "-")
      let documentUrl = documentDirectory.appendingPathComponent("\(normalizedTimestamp)_\(visitId)_\(sessionId)")
      try FileManager.default.createDirectory(at: documentUrl, withIntermediateDirectories: true, attributes: nil)
      directoryURL = documentUrl
    } catch {
      print(#function, "ERROR", error)
    }

    return directoryURL
  }
}

class SaveAnalyticsGeoPositionsToJSONFileUseCase {
  @Inject var persistence: PersistenceManager
  @Inject var repository: IAnalyticsRepository
  @Inject var statusRepository: IStatusRepository
  let business = SaveAnalyticsToFileBusiness()

  func invoke() {
    /// Extract current visit- and session Id
    /// Combine all visit geoPositions into one dictionary
    /// Convert to Json file
    /// Save Json file to directory found in the repository
    guard
      statusRepository.currentSettings.saveToDiskEnabled,
      let visitId = repository.activeVisitId
    else { return }
    let bundledGeoPositions = business.bundle(params: persistence.getGeoPositions())
    guard
      let visitGeoPositions = business.createVisitGeoPositions(geoPositionsBundles: bundledGeoPositions, visitId: visitId),
      let directoryURL = repository.directoryURLS[visitId]
    else { return }
    // todo get directoryURL from repository to save the data
    do {
      let jsonData = try JSONEncoder().encode(visitGeoPositions)
      try jsonData.write(to: directoryURL
        .appendingPathComponent("GeoPositions")
        .appendingPathComponent("geoPositions")
        .appendingPathExtension("json"))
    } catch {
      print(#function, "Couldn't encode data", error)
    }
  }
}

class SaveReplayDataToJSONUseCase {
  @Inject var repository: IAnalyticsRepository
  @Inject var statusRepository: IStatusRepository

  func invoke(object: AWSRecordedObject) {
    guard
      statusRepository.currentSettings.saveToDiskEnabled,
      let visitId = repository.activeVisitId,
      let directoryURL = repository.directoryURLS[visitId],
      let identifier = object.identifier,
      let data = object.data?.data(using: .utf8)
    else { return }
    DispatchQueue.global(qos: .background).async {
      let directoryURL = directoryURL.appendingPathComponent("ReplayData")
      do {
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
          try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        try data.write(to: directoryURL
          .appendingPathComponent(identifier)
          .appendingPathExtension("json"))
      } catch {
        print(#function, "Error saving ReplayData", error)
      }
    }
  }
}

class StreamToFileUseCase {
  @Inject var repository: IAnalyticsRepository
  @Inject var statusRepository: IStatusRepository
  let business = SaveAnalyticsToFileBusiness()
  let semaphore = DispatchSemaphore(value: 1)

  func invoke(param: UploadGeoPositionsParameters) {
    let bundledGeoPositions = business.bundle(params: [param])
    guard
      statusRepository.currentSettings.saveToDiskEnabled,
      let visitGeoPositions = business.createVisitGeoPositions(geoPositionsBundles: bundledGeoPositions, visitId: param.visitId),
      let directoryURL = repository.directoryURLS[param.visitId]
    else { return }
    DispatchQueue.global(qos: .background).async { [weak self] in
      guard let self = self else { return }
      semaphore.wait()
      do {
        try business.streamToFile(data: visitGeoPositions, directoryUrl: directoryURL)
        semaphore.signal()
      } catch {
        print("StreamToFile Error", error)
        semaphore.signal()
      }
    }
  }
}

class DeleteEmptyDirectoryUseCase {
  @Inject var repository: IStatusRepository
  let business = SaveAnalyticsToFileBusiness()
  func invoke() {
    guard
      repository.currentSettings.saveToDiskEnabled,
      let directoryUrl = FileManager.default.rootDirectory
    else { return }

    do {
      try FileManager.default
        .contentsOfDirectory(atPath: directoryUrl.path)
        .map {
          print("urlString", $0)
          return directoryUrl.appendingPathComponent($0)
        }
        .filter { $0.hasDirectoryPath }
        .forEach {
          print("try DELETE", $0)
          try business.deleteEmptyDirectories(at: $0)
        }
    } catch {
      print("Error deleting empty directories", error)
    }
  }
}

class SaveAnalyticsToFileBusiness {
  func deleteEmptyDirectories(at url: URL) throws {
    if !FileManager.default.fileExists(atPath: url.appendingPathComponent("GeoPositions").path) {
      print("DELETE", "1", url)
      try FileManager.default.removeItem(at: url)
    } else if try FileManager.default
      .contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
      .isEmpty {
      print("DELETE", "2", url)
      try FileManager.default.removeItem(at: url)
    }
  }

  func streamToFile(data: VisitGeoPositions, directoryUrl: URL) throws {
    let directoryUrl = directoryUrl.appendingPathComponent("GeoPositions")
    if !FileManager.default.fileExists(atPath: directoryUrl.path) {
      try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true)
    }
    try streamToFile(data: data.gpsPositions, url: directoryUrl
      .appendingPathComponent("gpsPositions")
      .appendingPathExtension("csv"))
    try streamToFile(data: data.tt2Positions, url: directoryUrl
      .appendingPathComponent("tt2Positions")
      .appendingPathExtension("csv"))
  }

  func streamToFile(data: [RecordedPositionLngLat], url: URL) throws {
    if !FileManager.default.fileExists(atPath: url.path), let data = "Timestamp,AirPressure,Longitude,Latitude\n".data(using: .utf8) {
      try data.write(to: url, options: .atomic)
    }
    let file = try FileHandle(forWritingTo: url)
    defer { file.closeFile() }
    data.forEach { (positions) in
      guard
        let data = "\(positions.timestamp),\(positions.airPressure?.description ?? "null"),\(positions.lngLat[0]),\(positions.lngLat[1])\n"
          .data(using: .utf8)
      else { return }
      file.seekToEndOfFile()
      file.write(data)
    }
  }

  func createVisitGeoPositions(geoPositionsBundles: [Int64: [String: [RecordedPositionLngLat]]], visitId: Int64) -> VisitGeoPositions? {
    guard geoPositionsBundles[visitId] != nil else { return nil }
    var visitGeoPositions = VisitGeoPositions(visitId: visitId, sessionId: 0, tt2Positions: [], gpsPositions: [])
    geoPositionsBundles[visitId]?.forEach { (key, value) in
      if key == UploadGeoPositionsParameters.TypeEnum.fullGPS.rawValue {
        visitGeoPositions.gpsPositions.append(contentsOf: value)
      } else if key == UploadGeoPositionsParameters.TypeEnum.fullVPSMl.rawValue {
        visitGeoPositions.tt2Positions.append(contentsOf: value)
      }
    }
    return visitGeoPositions
  }

  func bundle(params: [UploadGeoPositionsParameters]) -> [Int64: [String: [RecordedPositionLngLat]]]  {
    var visitGeoPositions: [Int64: [String: [RecordedPositionLngLat]]] = [:]
    params.forEach { (params) in
      if visitGeoPositions[params.visitId] == nil {
        visitGeoPositions[params.visitId] = params.positions
      } else {
        params.positions.forEach { (key, value) in
          if visitGeoPositions[params.visitId]?[key] == nil {
            visitGeoPositions[params.visitId]?[key] = value
          } else {
            visitGeoPositions[params.visitId]?[key]?.append(contentsOf: value)
          }
        }
      }
    }

    return visitGeoPositions
  }
}

struct VisitGeoPositions: Codable {
  var visitId: Int64
  var sessionId: Int64
  var tt2Positions: [RecordedPositionLngLat]
  var gpsPositions: [RecordedPositionLngLat]
}

extension FileManager {
  var createRootDirectory: URL {
    get throws {
      try FileManager.default
        .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent("TT2")
    }
  }

  var rootDirectory: URL? {
    FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("TT2")
  }
}
