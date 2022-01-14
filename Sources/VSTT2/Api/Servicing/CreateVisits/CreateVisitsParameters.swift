//
// CreateVisitsParameters
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct CreateVisitsParameters {
    @Inject var config: EnvironmentConfig

    private let apiKey: String
    private let requestId: String
    private let storeId: Int64
    private let start: String
    private let stop: String
    private let deviceInformation: DeviceInformation
    private let tags: [String: String]
    private let metaData: [String: String]

    public init(apiKey: String, requestId: String, storeId: Int64, start: String,
                stop: String, deviceInformation: DeviceInformation, tags: [String: String], metaData: [String: String]) {
        self.apiKey = apiKey
        self.requestId = requestId
        self.storeId = storeId
        self.start = start
        self.stop = stop
        self.deviceInformation = deviceInformation
        self.tags = tags
        self.metaData = metaData
    }
}

extension CreateVisitsParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    // Analytics base URL seems different, check if it will be the same after
    // Temprorary fix path sign issue and use v2/visits?requestId=\(requestId) as path
    var baseURL: String { "https://gunnis-hp-stat.ih.vs-office.se/api/v2/visits?requestId=\(requestId)" }

    var method: RequestType { .POST }

   // var path: String { "/v2/visits?requestId=\(requestId)" }

    var parameters: [String: Any]? {
        let parameters = ["storeId": storeId,
                          "start": start,
                          "stop": stop,
                          "deviceInformation": [
                              "operatingSystem": deviceInformation.operatingSystem,
                              "osVersion":deviceInformation.osVersion,
                              "appVersion": deviceInformation.appVersion,
                              "deviceModel": deviceInformation.deviceModel
                          ],
                          "tags": tags,
                          "metadata": metaData] as [String: Any]

        return parameters
    }

    var headers: [String: String]? { ["APIKey" : "8fc1be06-582e-41ce-b309-61e8fa8e3784" ] }
}
