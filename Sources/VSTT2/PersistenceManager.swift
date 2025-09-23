//
//  PersistenceManager.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-04-17.
//

import Foundation
import VSFoundation

public protocol IPersistenceManager {
  func countGeoPositions() -> Int
}

class PersistenceManager {
  @Inject var persistence: Persistence
  lazy var filePersistence = { FilePersistenceManager() }()

  var requestIdInProgress: [String] = []

  var geoPositions: [PersistGeoPositionsParameters] { persistence.get(arrayOf: PersistGeoPositionsParameters.self) }

  func getGeoPositions() -> [UploadGeoPositionsParameters] {
    geoPositions
      .map { $0.asParams }
      .compactMap { $0 }
      .filter {
        !$0.positions.keys.contains(UploadGeoPositionsParameters.TypeEnum.vpsMlProcessed.rawValue)
      }
  }

  func save(geoposition: UploadGeoPositionsParameters) {
    var object = PersistGeoPositionsParameters()
    object.visitId = geoposition.visitId
    object.requestId = geoposition.requestId
    object.positions = geoposition.positions
    do {
      try persistence.save(&object)
      filePersistence.save(geoposition: geoposition)
    } catch {
      print("GEOPOSITION SAVE ERROR: \(error)")
    }
  }

  func delete(with requestId: String) {
    if let object = geoPositions.first(where: { $0.requestId == requestId }) {
      try? persistence.delete(object)
    }
  }

  func deleteAll() {
    try? persistence.delete(by: PersistGeoPositionsParameters.self)
  }
}

extension PersistenceManager: IPersistenceManager {
  func countGeoPositions() -> Int {
    getGeoPositions().count
  }
}

class FilePersistenceManager {
  @Inject var streamToFile: StreamToFileUseCase

  func save(geoposition: UploadGeoPositionsParameters) {
    streamToFile.invoke(param: geoposition)
  }
}
