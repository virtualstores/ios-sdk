//
// ShelfGroupParameters
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct ShelfGroupParameters {
    private let storeId: String

    @Inject var config: EnvironmentConfig

    public init(storeId: String) {
        self.storeId = storeId
    }
}

extension ShelfGroupParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    var path: String { "/shelfgroups/\(storeId)/shelves" }
}
