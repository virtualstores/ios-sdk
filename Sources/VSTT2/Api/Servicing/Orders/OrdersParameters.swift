//
// OrdersParameters
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

struct OrdersParameters {
    @Inject var config: EnvironmentConfig
    let storeId: Int64
    let orderIds: [String]
    let deviceInformation: DeviceInformation
}

extension OrdersParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType? { .central }
    var method: RequestType { .POST }
    var path: String { "/orders" }
    var parametersDictionary: [String: Any]? {
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
