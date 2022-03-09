//
// OrdersParameters
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

public struct OrdersParameters {
    private let config: EnvironmentConfig
    private let storeId: Int64
    private let orderIds: [String]
    private let deviceInformation: DeviceInformation

    public init( storeId: Int64, orderIds: [String], deviceInformation: DeviceInformation, config: EnvironmentConfig) {
        self.storeId = storeId
        self.orderIds = orderIds
        self.deviceInformation = deviceInformation
        self.config = config
    }
}

extension OrdersParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var path: String { "/orders" }

    var parameters: [String: Any]? {
        let parameters = ["storeId": storeId,
                          "orderIds": orderIds,
                          "device": ["id": deviceInformation.id,
                                     "operatingSystem": deviceInformation.operatingSystem,
                                     "osVersion":deviceInformation.osVersion,
                                     "appVersion": deviceInformation.appVersion,
                                     "deviceModel": deviceInformation.deviceModel
                          ]] as [String: Any]

        return parameters
    }
}
