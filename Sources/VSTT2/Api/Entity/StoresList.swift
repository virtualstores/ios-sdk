//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-21.
//

import Foundation

public final class StoresList: Codable {
    public let stores: [Store]

    public init(stores: [Store]) {
        self.stores = stores
    }

    private enum CodingKeys: String, CodingKey {
        case stores
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stores = try container.decode([Store].self, forKey: .stores)
    }
}
