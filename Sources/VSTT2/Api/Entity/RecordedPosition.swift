//
// RecordedPosition
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation

struct RecordedPosition: Codable {
    let xPosition: Double
    let yPosition: Double
    let timestamp: String
    
    private enum CodingKeys: String, CodingKey {
        case xPosition = "x"
        case yPosition = "y"
        case timestamp = "timestamp"
    }
}

struct RecordedPositionLngLat: Codable {
  let airPressure: Double?
  let timestamp: String
  let lngLat: [Double]
}

final class RecordedPositionLngLatDTO: IPersistenceModel {
  var retainOriginalIndex: Bool = false
  var index: String?

  convenience init(index: String) {
    self.init()
    self.index = index
  }

  var airPressure: Double?
  var timestamp: String?
  var lngLat: [Double]?
  var visitId: Int64?
  var status: String?
}
