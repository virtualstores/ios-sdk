//
//  PersistenceManager.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-04-17.
//

import Foundation
import VSFoundation

class PersistenceManager {
  @Inject var persistence: Persistence

  var requestIdInProgress: [String] = []

  var geoPositions: [PersistGeoPositionsParameters] { persistence.get(arrayOf: PersistGeoPositionsParameters.self) }

  func getGeoPositions() -> [UploadGeoPositionsParameters] {
    geoPositions.map { $0.asParams }.compactMap { $0 }
  }

  func save(geoposition: UploadGeoPositionsParameters) {
    var object = PersistGeoPositionsParameters()
    object.visitId = geoposition.visitId
    object.requestId = geoposition.requestId
    object.positions = geoposition.positions
    do {
      try persistence.save(&object)
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
