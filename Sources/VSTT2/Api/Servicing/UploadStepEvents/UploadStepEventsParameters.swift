//
//  UploadStepEventsParameters.swift
//  
//
//  Created by Théodore Roos on 2022-09-28.
//

import Foundation

struct UploadStepEventsParameters {
  let config: EnvironmentConfig?

  let visitId: Int64
  let requestId: String

  let event: StepEvent
}

extension UploadStepEventsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var method: RequestType { .POST }

  var path: String { "/stepevents" }

  var queryItems: [String : String]? { ["visitId": String(visitId), "requestId": requestId] }

  var parameters: Any? {
    [
      [
        "rtlsOptionsId" : event.rtlsOptionsId,
        "type" : event.type,
        "timestamp" : event.timestamp,
        "success" : event.success,
        "duration" : event.duration,
        "direction" : event.direction,
        "directionCertainty" : event.directionCertainty,
        "relativeDirection" : event.relativeDirection,
        "stepCertainty" : event.stepCertainty,
        "speed" : event.speed
      ]
    ]
  }
}

struct StepEvent {
  let rtlsOptionsId: Int64
  let type: String
  let timestamp: Int64
  let success: Bool
  let duration: Double
  let direction: Double
  let directionCertainty: Double
  let relativeDirection: Double
  let stepCertainty: Double
  let speed: Double
}
