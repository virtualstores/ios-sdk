//
// ItemPositionParameters
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

public struct ItemPositionParameters {
    private let storeId: Int64
    private let barcode: String
    private let config: EnvironmentConfig?

    public init(storeId: Int64, barcode: String, config: EnvironmentConfig?) {
        self.storeId = storeId
        self.barcode = barcode
        self.config = config
    }
}

extension ItemPositionParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var path: String { "/shelfgroups/barcodes" }

    var method: RequestType { .GET }

    var queryItems: [String: String]? {
        let parameters = ["storeId": String(storeId),
                          "barcode": barcode] as [String: String]

        return parameters
    }
}
