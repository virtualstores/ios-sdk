//
//  File.swift
//  
//
//  Created by Théodore Roos on 2022-09-28.
//

import Foundation

struct UploadStepEventsParameters {
  let config: EnvironmentConfig?

  let visitId: Int64
  let requestId: String

  let stepEvent: StepEvent
}

extension UploadStepEventsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  
  var path: String {
    <#code#>
  }
}

struct StepEvent {
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
