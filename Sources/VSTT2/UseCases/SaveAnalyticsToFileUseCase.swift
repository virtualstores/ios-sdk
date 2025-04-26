// SaveAnalyticsToFileUseCase.swift
// VSTT2

// Created by: CJ on 2025-04-25
// Copyright (c) 2025
import Foundation
import VSFoundation


class CreateOfflineVisitDirectoryUseCase {
  @Inject var repository: IAnalyticsRepository

  func invoke() {
    /// todo
    /// Create a directory: 2025-04-25T10-50-34_visitId_sessionId
    if let visitId = repository.activeVisitId {
      let directoryURL = CreateOfflineVisitDirectoryBussiness().invoke(visitId: visitId, sessionId: 0, timestamp: DateFormatter.standardFormatter.string(from: Date()))
      if let directoryURL = directoryURL {
        // todo save directory Url in repository dict [visitId+sessionId:directoryUrl]
        repository.setDirectoryURL(visitId: visitId, url: directoryURL)
      }
    }
  }
}

class CreateOfflineVisitDirectoryBussiness {

  func invoke(visitId: Int64, sessionId: Int64, timestamp: String) -> URL? {
    /// Create a directory: 2025-04-25T10-50-34_visitId_sessionId
    /// Set directory in repoisitory

    var directoryURL: URL? = nil

    let normalizedTimestamp = timestamp.replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: ".", with: "-")

    if #available(iOS 14.0, *) {
      do {

        let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let ducumentUrl = documentDirectory.appendingPathComponent("\(normalizedTimestamp)_\(visitId)_\(sessionId)", conformingTo: .directory)

        do {
          try FileManager.default.createDirectory(at: ducumentUrl, withIntermediateDirectories: true, attributes: nil)
          directoryURL = ducumentUrl
        } catch {
          print("Failed to create directory: $\(error.localizedDescription)")
        }
      } catch {
        print("Failed to directory path: $\(error.localizedDescription)")
      }
    } else {
      // Fallback on earlier versions
    }

    return directoryURL
  }
}



class SaveAnalyticsToFileUseCase {
  @Inject var persistence: PersistenceManager
  @Inject var repository: IAnalyticsRepository

  func invoke(){
    /// Extract current visit- and session Id
    /// Combine all visit geoPositions into one dictionary
    /// Convert to Json file
    /// Save Json file to directory found in the repository

    let bussiness = SaveAnalyticsToFileBussiness()

    if let visitId = repository.activeVisitId {
      let bundledGeoPositions = bussiness.bundleGeoPositionsParameters(geoPositions: persistence.getGeoPositions())
      let visitGeoPositions = bussiness.createVisitGeoPositions(geoPositionsBundles: bundledGeoPositions, visitId: visitId)
      if let visitGeoPositions = visitGeoPositions {
        // todo get directoryURL from repository to save the data
        if let directoryURL = repository.directoryURLS[visitId]{
          bussiness.writeToFile(data: visitGeoPositions, directoryUrl: directoryURL)
        }
      }
    }
  }
}


class SaveAnalyticsToFileBussiness {

  func writeToFile(data: VisitGeoPositions, directoryUrl: URL) {

    if let jsonData = try? JSONEncoder().encode(data) {

      do {
        let fileUrl = directoryUrl.appendingPathComponent("geoPositions.json")
        try jsonData.write(to: fileUrl)

      } catch {

      }
    }
  }


  func createVisitGeoPositions(geoPositionsBundles: [Int64: [String: [RecordedPositionLngLat]]], visitId: Int64) -> VisitGeoPositions? {
    if geoPositionsBundles[visitId] == nil {
      return nil
    } else {
      var visitGeoPositions = VisitGeoPositions(visitId: visitId, sessionId: 0, tt2Positions: [], gpsPositions: [])
      geoPositionsBundles[visitId]?.forEach { key, value in
        if key == "full-gps" {
          visitGeoPositions.gpsPositions.append(contentsOf: value)
        } else if key == "full-tt2" {
          visitGeoPositions.tt2Positions.append(contentsOf: value)
        }
      }
      return visitGeoPositions
    }
  }

  func bundleGeoPositionsParameters(geoPositions: [UploadGeoPositionsParameters]) -> [Int64: [String: [RecordedPositionLngLat]]]  {

    var visitGeoPositions: [Int64: [String: [RecordedPositionLngLat]]] = [:]

    geoPositions.forEach { part in
      if visitGeoPositions[part.visitId] == nil {
        visitGeoPositions[part.visitId] = part.positions
      } else {
        part.positions.forEach { key, value in
          if visitGeoPositions[part.visitId]?[key] == nil {
            visitGeoPositions[part.visitId]?[key] = value
          } else {
            visitGeoPositions[part.visitId]?[key]?.append(contentsOf: value)
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
