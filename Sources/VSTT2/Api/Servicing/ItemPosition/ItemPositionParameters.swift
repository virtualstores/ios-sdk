//
// ItemPositionParameters
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

struct ItemPositionParameters {
    let config: EnvironmentConfig
    let storeId: Int64
    let barcode: String
}

extension ItemPositionParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var method: RequestType { .GET }

    var path: String { "/shelfgroups/barcodes" }

    var type: RoutingType { .central }

    var queryItems: [String: String]? {
        let parameters = ["storeId": String(storeId),
                          "barcode": barcode] as [String: String]

        return parameters
    }
}
