//
//  UploadZoneSummary.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-06-27.
//

import Combine
import VSFoundation

final class UploadZoneSummaryService: DataFetchingManager {
  func call(with parameters: UploadZoneSummaryParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}

struct UploadZoneSummaryParameters {
  @Inject var config: EnvironmentConfig
  let visitId: Int64
  let requestId: String
  let summary: [String: AnalyticsZoneSummaryBusiness.ZoneCountsDTO]
}

extension UploadZoneSummaryParameters: Routing {
  var environmentConfig: EnvironmentConfig? { config }
  var type: RoutingType { .analytics }
  var method: RequestType { .PATCH }
  var path: String { "/zones" }
  var queryItems: [String: String]? {
    ["visitId": String(visitId), "requestId": requestId]
  }
  var parameters: Any? {
    summary.asDictionary()
  }
}
