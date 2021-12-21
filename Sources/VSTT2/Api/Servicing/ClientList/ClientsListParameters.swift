//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-20.
//
import Foundation

public struct ClientsListParameters {
    public init() {}
}

extension ClientsListParameters: Routing {
    var path: String {
        return "/api/v1/clients"
    }
}
