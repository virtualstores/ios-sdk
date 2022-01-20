//
// UploadPositionsParameters
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct UploadPositionsParameters {
    @Inject var config: EnvironmentConfig

    private let visitId: Int64
    private let requestId: String
    let positionGrps: [String: [RecordedPosition]]

    init(visitId: Int64, requestId: String, positionGrps: [String: [RecordedPosition]]) {
        self.visitId = visitId
        self.requestId = requestId
        self.positionGrps = positionGrps
    }
}

extension UploadPositionsParameters: Routing {
    var environmentConfig: EnvironmentConfig { .analytics }

    var path: String { "/positions" }

    var queryItems: [String: String]? {
        let parameters = ["visitId": String(visitId), "requestId": requestId] as [String: String]

        return parameters
    }
    
    var parameters: [String: Any]? {
        let parameters = ["positionGrps": positionGrps.asDictionary()] as [String: Any]

        return parameters
    }

    var headers: [String: String]? { ["apiKey" : "8fc1be06-582e-41ce-b309-61e8fa8e3784" ] }
}
