//
// StoresListParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

public struct StoresListParameters {
    private let clientId: String

    public init(clientId: String) {
        self.clientId = clientId
    }
}

extension StoresListParameters: Routing {
    var path: String {
        return "/clients/\(clientId)/stores"
    }
}
