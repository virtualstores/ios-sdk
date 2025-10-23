//
//  UploadVisitScore.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-02-26.
//

import Combine
import Foundation
import VSFoundation

final class UploadVisitScoreService: DataFetchingManager {
  func call(with parameters: UploadVisitScoreParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}

struct UploadVisitScoreParameters {
  @Inject var config: EnvironmentConfig
  var visitId: Int64
  let requestId: String
  let visitScore: VisitScore
}

extension UploadVisitScoreParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType? { .analytics }
  var method: RequestType { .PUT }
  var path: String { "/visits/score" }
  var queryItems: [String: String]? {
    ["requestId": requestId, "visitId": String(visitId)]
  }
  var parameters: Any? {
    [
      "score": visitScore.score,
      "hasAcceptedScore": visitScore.isAccepted,
      "timestamp": DateFormatter.standardFormatter.string(from: visitScore.timestamp)
    ]
  }
}
