//
// SwapLocationsParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

struct SwapLocationsParameters {
    @Inject var config: EnvironmentConfig
    let storeId: Int64
}

extension SwapLocationsParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType { .central }
    var method: RequestType { .GET }
    var path: String { "/swaplocations" }
    var queryItems: [String: String]? {
        let parameters = ["storeId": String(storeId)] as [String: String]

        return parameters
    }
}
