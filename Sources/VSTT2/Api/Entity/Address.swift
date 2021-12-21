//
// Address
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

public struct Address: Codable {
    public let city: String?
    public let zipCode: String?
    public let address: String?
    public let description: String?

    public init(city: String?, zipCode: String?, address: String?, description: String?) {
        self.city = city
        self.zipCode = zipCode
        self.address = address
        self.description = description
    }
}
