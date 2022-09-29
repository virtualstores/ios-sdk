//
// StoresListParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

struct StoresListParameters {
    private let clientId: Int64
    private var config: EnvironmentConfig?

    init(clientId: Int64, config: EnvironmentConfig) {
        self.clientId = clientId
        self.config = config
    }
}

extension StoresListParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var method: RequestType { .GET }

    var path: String { "/clients/\(clientId)/stores" }
}
