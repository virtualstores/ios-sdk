//
// ClientsListParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

public struct ClientsListParameters {
    public init() {}
}

extension ClientsListParameters: Routing {
    var path: String {
        return "/clients"
    }
}
