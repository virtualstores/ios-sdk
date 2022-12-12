//
//  StepEventUploader.swift
//  
//
//  Created by Théodore Roos on 2022-09-29.
//

import Combine
import Foundation
import VSFoundation

class StepEventUploader {
  @Inject var analytics: TT2AnalyticsManager
  @Inject var stepEventService: UploadStepEventsService
  @Inject var persistence: Persistence

  var events: [StepEventData] = []

  private var cancellable = Set<AnyCancellable>()

  deinit {
    cancellable.removeAll()
  }

  func upload() {
    guard
      let visitId = analytics.visitId,
      let rtlsOptionId = analytics.rtlsOptionId
    else { return }
    let events: [StepEvent] = events.map { $0.asStepEvent(rtlsOptionsId: rtlsOptionId) }
    let parameters = UploadStepEventsParameters(
      config: analytics.config,
      visitId: visitId,
      requestId: UUID().uuidString.uppercased(),
      events: events
    )
    do {
      var persistence = parameters.asPersistence
      try self.persistence.save(&persistence)
      upload(parameters: parameters)
      self.events.removeAll()
    } catch {
      Logger(verbosity: .error).log(message: "UploadStepEventsPersistanceSaveError \(error)")
    }
  }

  private func upload(parameters: UploadStepEventsParameters) {
    stepEventService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): print("UploadStepEventsParametersError", error.localizedDescription)
        }
      } receiveValue: { (_) in
        let persistence = parameters.asPersistence
        do {
          try self.persistence.delete(persistence)
        } catch {
          Logger(verbosity: .error).log(message: "UploadStepEventsPersistenceDeleteError \(error)")
        }
      }.store(in: &cancellable)
  }
}

extension StepEventData {
  func asStepEvent(rtlsOptionsId: Int64) -> StepEvent {
    StepEvent(
      rtlsOptionsId: rtlsOptionsId,
      type: type?.rawValue,
      timestamp: timestamp,
      success: success,
      duration: duration,
      direction: direction,
      directionCertainty: directionCertainty,
      relativeDirection: relativeDirection,
      stepCertainty: stepCertainty,
      speed: speed,
      mlAdjustmentSpeedModelFactor: mlAdjustment?.speedModelFactor,
      mlAdjustmentSpeedAdjuster: mlAdjustment?.speedAdjuster,
      mlAdjustmentDriftInRadians: mlAdjustment?.driftInRadians,
      mlAdjustmentRotationInRadians: mlAdjustment?.rotationInRadians,
      quaternion: quaternion
    )
  }
}

extension UploadStepEventsParameters {
  var asPersistence: UploadStepEventsPersistence {
    let persistence = UploadStepEventsPersistence()
    persistence.apiKey = config?.centralServerConnection.apiKey
    persistence.serverAddress = config?.centralServerConnection.serverAddress
    persistence.mqttAddress = config?.centralServerConnection.mqttAddress
    persistence.storeId = config?.centralServerConnection.storeId
    persistence.visitId = visitId
    persistence.requestId = requestId
    persistence.events = events
    return persistence
  }
}
extension UploadStepEventsPersistence {
  var asParametes: UploadStepEventsParameters? {
    guard
      let visitId = visitId,
      let requestId = requestId,
      let events = events
    else { return nil }
    let config = EnvironmentConfig()
    config.centralServerConnection = ServerConnection(apiKey: apiKey, serverAddress: serverAddress, mqttAddress: mqttAddress, storeId: storeId)
    return UploadStepEventsParameters(config: config, visitId: visitId, requestId: requestId, events: events)
  }
}
