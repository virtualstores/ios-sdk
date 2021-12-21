//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-20.
//

import Foundation

public struct StoresListParameters {
    private let clientId: String

    public init(clientId: String) {
        self.clientId = clientId
    }
}

extension StoresListParameters: Routing {
    var path: String {
        return "/api/v1/clients/\(clientId)/stores"
    }
}
