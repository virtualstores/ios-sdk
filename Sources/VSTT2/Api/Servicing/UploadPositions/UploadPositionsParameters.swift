//
// UploadPositionsParameters
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct UploadPositionsParameters {
    private var config: EnvironmentConfig?
    private let visitId: Int64
    private let requestId: String
    let positionGrps: [String: [RecordedPosition]]

    init(visitId: Int64, requestId: String, positionGrps: [String: [RecordedPosition]], config: EnvironmentConfig?) {
        self.visitId = visitId
        self.requestId = requestId
        self.positionGrps = positionGrps
        self.config = config
    }
}

extension UploadPositionsParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var path: String { "/positions" }

    var queryItems: [String: String]? {
        let parameters = ["requestId": requestId, "visitId": String(visitId)] as [String: String]

        return parameters
    }

    var parameters: [String: Any]? {
        let parameters = ["positionGrps": positionGrps.asDictionary()] as [String: Any]

        return parameters
    }
}
