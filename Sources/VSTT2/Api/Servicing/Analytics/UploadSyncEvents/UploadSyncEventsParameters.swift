//
//  UploadSyncEvents.swift
//  
//
//  Created by Théodore Roos on 2022-09-19.
//

import Foundation
import CoreGraphics
import VSFoundation

struct UploadSyncEventsParameters {
  @Inject var config: EnvironmentConfig
  let visitId: Int64
  let requestId: String
  let event: SyncEvent
}

extension UploadSyncEventsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType? { .analytics }
  var method: RequestType { .POST }
  var path: String { "/syncevents" }
  var queryItems: [String: String]? {
    ["visitId": String(visitId), "requestId": requestId]
  }

  var parameters: Any? {
    [
      [
        "rtlsOptionsId" : event.rtlsOptionsId,
        "identifier" : event.identifier,
        "isRightAisle" : event.isRightAisle,
        "isFloorSwap" : event.isFloorSwap,
        "didSync" : event.didSync,
        "rescueModeCountSinceLastSync" : event.rescueModeCountSinceLastSync,
        "stepDataDistanceSinceLastSyncInMeters" : event.stepDataDistanceSinceLastSyncInMeters,
        "userToSyncPositionDistanceInMeters" : event.userToSyncPositionDistanceInMeters,
        "errorAngleInDegrees" : event.errorAngleInDegrees,
        "timestamp" : DateFormatter.standardFormatter.string(from: event.timestamp),
        "userPositionInMeters" : [
          "x" : event.userPositionInMeters.x,
          "y" : event.userPositionInMeters.y
        ],
        "syncPositionInMeters" : [
          "x" : event.syncPositionInMeters.x,
          "y" : event.syncPositionInMeters.y
        ],
        "syncPositionOffsetsInMeters" : [
          "x" : event.syncPositionOffsetsInMeters.dx,
          "y" : event.syncPositionOffsetsInMeters.dy
        ],
        "tags" : event.tags.asDictionary()
      ] as [String : Any]
    ]
  }
}

struct SyncEvent {
  let rtlsOptionsId: Int64
  let identifier: String
  let isRightAisle: Bool
  let isFloorSwap: Bool
  let didSync: Bool
  let rescueModeCountSinceLastSync: Int64
  let stepDataDistanceSinceLastSyncInMeters: Double
  let userToSyncPositionDistanceInMeters: Double
  let errorAngleInDegrees: Double
  let timestamp: Date
  let userPositionInMeters: CGPoint
  let syncPositionInMeters: CGPoint
  let syncPositionOffsetsInMeters: CGVector
  let tags: [String:String]
}

final class UploadSyncEventsPersistence: IPersistenceModel {
  var retainOriginalIndex: Bool = false
  var index: String?

  convenience init(index: String) {
    self.init()
    self.index = index
  }

  var visitId: Int64?
  var requestId: String?

  // event
  var rtlsOptionsId: Int64?
  var identifier: String?
  var isRightAisle: Bool?
  var isFloorSwap: Bool?
  var didSync: Bool?
  var rescueModeCountSinceLastSync: Int64?
  var stepDataDistanceSinceLastSyncInMeters: Double?
  var userToSyncPositionDistanceInMeters: Double?
  var errorAngleInDegrees: Double?
  var timestamp: Date?
  var userPositionInMeters: CGPoint?
  var syncPositionInMeters: CGPoint?
  var syncPositionOffsetsInMeters: CGVector?
  var tags: [String:String]?
}
