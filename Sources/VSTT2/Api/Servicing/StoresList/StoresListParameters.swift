//
// StoresListParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

struct StoresListParameters {
    @Inject var config: EnvironmentConfig
    let clientId: Int64

    init(clientId: Int64) {
        self.clientId = clientId
    }
}

extension StoresListParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType { .central }
    var method: RequestType { .GET }
    var path: String { "/clients/\(clientId)/stores" }
}
