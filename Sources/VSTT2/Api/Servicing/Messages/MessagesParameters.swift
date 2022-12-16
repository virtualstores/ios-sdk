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
    private let config: EnvironmentConfig?

    private init(storeId: Int64, config: EnvironmentConfig?) {
        self.storeId = storeId
        self.config = config
    }
}

extension MessagesParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }

    var method: RequestType { .GET }
    
    var path: String { "/messages" }
    
    var queryItems: [String: String]? {
        let parameters = ["storeId": String(storeId)] as [String: String]

        return parameters
    }
    
}
