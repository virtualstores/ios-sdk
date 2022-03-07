//
// ClientsListParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct ClientsListParameters {
    private var config: EnvironmentConfig

    public init(config: EnvironmentConfig) {
        self.config = config
    }
}

extension ClientsListParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var path: String { "/clients" }

    var method: RequestType { .GET }
}
