//
// MessagesParameters
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

struct MessagesParameters {
    @Inject var config: EnvironmentConfig
    let storeId: Int64
}

extension MessagesParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType? { .central }
    var method: RequestType { .GET }
    var path: String { "/messages" }
    var queryItems: [String: String]? {
        ["storeId": String(storeId)]
    }
}
