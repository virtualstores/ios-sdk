//
// Store
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

public final class Store: Codable {
    public let storeId: Int
    public let name: String?

    public init(storeId: Int, name: String?) {
        self.storeId = storeId
        self.name = name
    }

    private enum CodingKeys: String, CodingKey {
        case storeId = "id"
        case name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        storeId = try container.decode(Int.self, forKey: .storeId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }
}

