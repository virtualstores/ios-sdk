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
    var type: RoutingType { .analytics }
    var method: RequestType { .POST }
    var path: String { "/positions" }
    var queryItems: [String: String]? {
        ["requestId": requestId, "visitId": String(visitId)]
    }

    var parametersDictionary: [String: Any]? {
        ["positionGrps": positionGrps.asDictionary()] as [String: Any]
    }
}
