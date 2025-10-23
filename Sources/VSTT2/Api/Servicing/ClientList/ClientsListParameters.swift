//
// ClientsListParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

struct ClientsListParameters {
    @Inject var config: EnvironmentConfig
}

extension ClientsListParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType? { .central }
    var method: RequestType { .GET }
    var path: String { "/clients" }
}
