//
// CreateVisitParameters
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct CreateVisitParameters {
    private var config: EnvironmentConfig?
    private let requestId: String
    private let storeId: Int64
    private let start: String
    private let stop: String
    private let deviceInformation: DeviceInformation
    private let tags: [String: String]
    private let metaData: [String: String]

    public init(requestId: String, storeId: Int64, start: String,
                stop: String, deviceInformation: DeviceInformation, tags: [String: String], metaData: [String: String], config: EnvironmentConfig?) {
        self.requestId = requestId
        self.storeId = storeId
        self.start = start
        self.stop = stop
        self.deviceInformation = deviceInformation
        self.tags = tags
        self.metaData = metaData
        self.config = config
    }
}

extension CreateVisitParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var queryItems: [String: String]? {
        let parameters = ["requestId": requestId] as [String: String]

        return parameters
    }

    var path: String { "/visits" }

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
}
