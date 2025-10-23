//
// ShelfGroupParameters
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

struct ShelfGroupParameters {
    @Inject var config: EnvironmentConfig
    let rtlsOptionsId: Int64
}

extension ShelfGroupParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType? { .central }
    var method: RequestType { .GET }
    var path: String { "/shelfgroups" }
    var queryItems: [String: String]? {
        ["rtlsOptionsId": String(rtlsOptionsId)]
    }
}
