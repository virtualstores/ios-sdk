//
// Store
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021


import Foundation

public extension Store {
    func toTT2Store() -> TT2Store {
        return TT2Store(id: id, externalId: externalId, name: name, address: address, latitude: latitude, longitude: longitude, active: active)
    }
}
