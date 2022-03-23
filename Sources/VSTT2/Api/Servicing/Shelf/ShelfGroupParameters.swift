//
// ShelfGroupParameters
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct ShelfGroupParameters {
    private let config: EnvironmentConfig
    private let storeId: Int64
    private let rtlsOptionsId: Int64

    public init(storeId: Int64, rtlsOptionsId: Int64, config: EnvironmentConfig) {
        self.config = config
        self.storeId = storeId
        self.rtlsOptionsId = rtlsOptionsId
    }
}

extension ShelfGroupParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var path: String { "/shelfgroups" }

    var queryItems: [String: String]? {
        let parameters = [
          "storeId" : String(storeId),
          "rtlsOptionsId": String(rtlsOptionsId)
        ] as [String: String]

        return parameters
    }

    var method: RequestType { .GET }

}
