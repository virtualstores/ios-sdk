//
// StoresListParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct StoresListParameters {
    private let clientId: String

    @Inject var config: EnvironmentConfig

    public init(clientId: String) {
        self.clientId = clientId
    }
}

extension StoresListParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    var path: String { "/clients/\(clientId)/stores" }
}
