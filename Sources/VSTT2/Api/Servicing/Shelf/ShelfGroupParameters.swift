//
// ShelfGroupParameters
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct ShelfGroupParameters {
    private let storeId: Int64

    @Inject var config: EnvironmentConfig

    public init(storeId: Int64) {
        self.storeId = storeId
    }
}

extension ShelfGroupParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    var path: String { "/shelfgroups" }

    var queryItems: [String: String]? {
        let parameters = ["rtlsOptionsId": String(storeId)] as [String: String]

        return parameters
    }
    
    var method: RequestType { .GET }

}
