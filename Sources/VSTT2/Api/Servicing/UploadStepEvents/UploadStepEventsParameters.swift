//
//  UploadStepEventsParameters.swift
//  
//
//  Created by Théodore Roos on 2022-09-28.
//

import Foundation
import VSFoundation

struct UploadStepEventsParameters {
  let config: EnvironmentConfig
  let visitId: Int64
  let requestId: String
  let events: [StepEvent]
}

extension UploadStepEventsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .analytics }
  var method: RequestType { .POST }
  var path: String { "/stepevents" }
  var queryItems: [String : String]? { ["visitId": String(visitId), "requestId": requestId] }
  var parameters: Any? {
    var parameters: [[String:Any]] = []
    events.forEach { (event) in
      var mlAdjustmens: [String:Double]?
      if let speedModelFactor = event.mlAdjustmentSpeedModelFactor,
         let speedAdjuster = event.mlAdjustmentSpeedAdjuster,
         let driftInRadians = event.mlAdjustmentDriftInRadians,
         let rotationInRadians = event.mlAdjustmentRotationInRadians {
        mlAdjustmens = [
          "speedModelFactor" : speedModelFactor,
          "speedAdjuster" : speedAdjuster,
          "driftInRadians" : driftInRadians,
          "rotationInRadians" : rotationInRadians
        ]
      }
      parameters.append([
        "rtlsOptionsId" : event.rtlsOptionsId,
        "type" : event.type as Any,
        "timestamp" : event.timestamp,
        "sensorTimestamp": event.sensorTimestamp,
        "success" : event.success,
        "duration" : event.duration,
        "direction" : event.direction as Any,
        "directionCertainty" : event.directionCertainty as Any,
        "relativeDirection" : event.relativeDirection as Any,
        "stepCertainty" : event.stepCertainty,
        "speed" : event.speed as Any,
        "mlAdjustment" : mlAdjustmens?.asDictionary() as Any,
        "quaternion" : event.quaternion
      ])
    }
    return parameters
  }
}

final class UploadStepEventsPersistence: IPersistenceModel {
  var retainOriginalIndex: Bool = false
  var index: String?

  convenience init(index: String) {
    self.init()
    self.index = index
  }
  // config
  var apiKey: String?
  var serverAddress: String?
  var mqttAddress: String?
  var storeId: Int64?

  var visitId: Int64?
  var requestId: String?

  // event
  var events: [StepEvent]?
}

struct StepEvent: Codable {
  let rtlsOptionsId: Int64
  let type: String?
  let timestamp: Int64
  let sensorTimestamp: Int64
  let success: Bool
  let duration: Int64
  let direction: Double?
  let directionCertainty: Double?
  let relativeDirection: Double?
  let stepCertainty: Double
  let speed: Double?
  let mlAdjustmentSpeedModelFactor: Double?
  let mlAdjustmentSpeedAdjuster: Double?
  let mlAdjustmentDriftInRadians: Double?
  let mlAdjustmentRotationInRadians: Double?
  let quaternion: [Double]
}
