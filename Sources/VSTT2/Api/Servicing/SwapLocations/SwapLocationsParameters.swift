//
// SwapLocationsParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

public struct SwapLocationsParameters {
    private let storeId: Int64

    @Inject var config: EnvironmentConfig

    public init(storeId: Int64) {
        self.storeId = storeId
    }
}

extension SwapLocationsParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }
    
    var path: String { "/swaplocations" }

    var method: RequestType { .GET }

    var queryItems: [String: String]? {
        let parameters = ["storeId": String(storeId)] as [String: String]

        return parameters
    }
}
