//
//  UploadSyncEvents.swift
//  
//
//  Created by Théodore Roos on 2022-09-19.
//

import Foundation
import CoreGraphics

struct UploadSyncEventsParameters {
  let config: EnvironmentConfig?

  let visitId: Int64
  let requestId: String

  let event: SyncEvent

  var dto: SyncEventDto {
    SyncEventDto(
      rtlsOptionsId: event.rtlsOptionsId,
      identifier: event.identifier,
      isRightAisle: event.isRightAisle,
      isFloorSwap: event.isFloorSwap,
      didSync: event.didSync,
      rescueModeCountSinceLastSync: event.rescueModeCountSinceLastSync,
      stepDataDistanceSinceLastSyncInMeters: event.stepDataDistanceSinceLastSyncInMeters,
      userToSyncPositionDistanceInMeters: event.userToSyncPositionDistanceInMeters,
      errorAngleInDegrees: event.errorAngleInDegrees,
      timestamp: event.timestamp,
      userPositionInMeters: [
        "x": event.userPositionInMeters.x,
        "y": event.userPositionInMeters.y
      ],
      syncPositionInMeters: [
        "x": event.syncPositionInMeters.x,
        "y": event.syncPositionInMeters.y
      ],
      syncPositionOffsetsInMeters: [
        "x": event.syncPositionOffsetsInMeters.dx,
        "y": event.syncPositionOffsetsInMeters.dy
      ],
      tags: event.tags
    )
  }
}

extension UploadSyncEventsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }

  var path: String { "/syncevents" }

  var queryItems: [String: String]? {
    let parameters = ["visitId": String(visitId), "requestId": requestId] as [String: String]

    return parameters
  }

//  var parametersDictionary: [String : Any]? {
////    [ "Test": [
////        [
////          "rtlsOptionsId" : event.rtlsOptionsId,
////          "identifier" : event.identifier,
////          "isRightAisle" : event.isRightAisle,
////          "isFloorSwap" : event.isFloorSwap,
////          "didSync" : event.didSync,
////          "rescueModeCountSinceLastSync" : event.rescueModeCountSinceLastSync,
////          "stepDataDistanceSinceLastSyncInMeters" : event.stepDataDistanceSinceLastSyncInMeters,
////          "userToSyncPositionDistanceInMeters" : event.userToSyncPositionDistanceInMeters,
////          "errorAngleInDegrees" : event.errorAngleInDegrees,
////          "timestamp" : DateFormatter.standardFormatter.string(from: event.timestamp),
////          "userPositionInMeters" : [
////            "x" : event.userPositionInMeters.x,
////            "y" : event.userPositionInMeters.y
////          ],
////          "syncPositionInMeters" : [
////            "x" : event.syncPositionInMeters.x,
////            "y" : event.syncPositionInMeters.y
////          ],
////          "syncPositionOffsetsInMeters" : [
////            "x" : event.syncPositionOffsetsInMeters.dx,
////            "y" : event.syncPositionOffsetsInMeters.dy
////          ],
////          "tags" : event.tags.asDictionary(),
////        ]
////      ]
////    ]
//
//    [ "Test": [dto.asDictionary()] ]
//  }

  var parametersAny: Any? {
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
        "tags" : event.tags.asDictionary(),
      ]
    ]
  }
}

struct SyncEvent: Codable {
  let rtlsOptionsId: Int64
  let identifier: String
  let isRightAisle: Bool
  let isFloorSwap: Bool
  let didSync: Bool
  let rescueModeCountSinceLastSync: Double
  let stepDataDistanceSinceLastSyncInMeters: Double
  let userToSyncPositionDistanceInMeters: Double
  let errorAngleInDegrees: Double
  let timestamp: Date
  let userPositionInMeters: CGPoint
  let syncPositionInMeters: CGPoint
  let syncPositionOffsetsInMeters: CGVector
  let tags: [String:String]
}

struct SyncEventDto: Codable {
  let rtlsOptionsId: Int64
  let identifier: String
  let isRightAisle: Bool
  let isFloorSwap: Bool
  let didSync: Bool
  let rescueModeCountSinceLastSync: Double
  let stepDataDistanceSinceLastSyncInMeters: Double
  let userToSyncPositionDistanceInMeters: Double
  let errorAngleInDegrees: Double
  let timestamp: Date
  let userPositionInMeters: [String:Double]
  let syncPositionInMeters: [String:Double]
  let syncPositionOffsetsInMeters: [String:Double]
  let tags: [String:String]
}
