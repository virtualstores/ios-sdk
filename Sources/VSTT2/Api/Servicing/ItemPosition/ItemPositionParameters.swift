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

    @Inject var config: EnvironmentConfig

    public init(storeId: Int64, barcode: String) {
        self.storeId = storeId
        self.barcode = barcode
    }
}

extension ItemPositionParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    var path: String { "/shelfgroups/barcodes" }

    var method: RequestType { .GET }

    var queryItems: [String: String]? {
        let parameters = ["storeId": String(storeId),
                          "barcode": barcode] as [String: String]

        return parameters
    }
}
