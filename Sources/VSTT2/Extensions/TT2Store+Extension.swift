//
// Store
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021


import Foundation

public extension Store {
    func toTT2Store() -> TT2Store {
        return TT2Store(id: self.id, externalId: self.externalId, name: self.name, address: self.address, latitude: self.latitude, longitude: self.longitude, active: self.active, startScanLocations: self.startCodes, stopScanLocations: self.stopCodes)
    }
}
