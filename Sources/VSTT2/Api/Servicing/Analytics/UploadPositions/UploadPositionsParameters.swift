//
// UploadPositionsParameters
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

struct UploadPositionsParameters {
  @Inject var config: EnvironmentConfig
  let visitId: Int64
  let requestId: String
  let positionGrps: [String: [RecordedPosition]]
}

extension UploadPositionsParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType? { .analytics }
  var method: RequestType { .POST }
  var path: String { "/positions" }
  var queryItems: [String: String]? {
    ["requestId": requestId, "visitId": String(visitId)]
  }

  var parametersDictionary: [String: Any]? {
    ["positionGrps": positionGrps.asDictionary()] as [String: Any]
  }
}

final class UploadPositionsPersistence: IPersistenceModel {
  var retainOriginalIndex: Bool = false
  var index: String?

  convenience init(index: String) {
    self.init()
    self.index = index
  }

  var visitId: Int64?
  var requestId: String?
  var positionGrps: [String: [RecordedPosition]]?
  var status: String?
}

extension UploadPositionsPersistence {
  var asParameters: UploadPositionsParameters? {
    guard
      let visitId = visitId,
      let requestId = requestId,
      let positionGrps = positionGrps
    else { return nil }
    return .init(
      visitId: visitId,
      requestId: requestId,
      positionGrps: positionGrps
    )
  }
}
