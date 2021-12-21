//
// ClientsListParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct ClientsListParameters {
    @Inject var config: EnvironmentConfig

    public init() {}
}

extension ClientsListParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    var path: String { "/clients" }
}
