//
// CreateVisitParameters
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

struct CreateVisitParameters {
    @Inject var config: EnvironmentConfig
    let requestId: String
    let storeId: Int64
    let start: String
    let stop: String
    let deviceInformation: DeviceInformation
    let tags: [String: String]
    let metaData: [String: String]
}

extension CreateVisitParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType { .analytics }
    var method: RequestType { .POST }
    var path: String { "/visits" }
    var queryItems: [String: String]? { ["requestId": requestId] as [String: String] }

    var parametersDictionary: [String: Any]? {
        [
            "storeId": storeId,
            "start": start,
            "stop": stop,
            "deviceInformation": [
                "operatingSystem": deviceInformation.operatingSystem,
                "osVersion":deviceInformation.osVersion,
                "appVersion": deviceInformation.appVersion,
                "deviceModel": deviceInformation.deviceModel
            ],
            "tags": tags,
            "metadata": metaData
        ]
    }
}
