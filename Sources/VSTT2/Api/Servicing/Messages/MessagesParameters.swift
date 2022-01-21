//
// MessagesParameters
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct MessagesParameters {
    private let storeId: Int64

    @Inject var config: EnvironmentConfig

    public init(storeId: Int64) {
        self.storeId = storeId
    }
}

extension MessagesParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    var path: String { "messages?storeId=\(storeId)" }
}
