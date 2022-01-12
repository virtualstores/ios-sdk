//
// VSTT2
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import Combine

/// Manager for VSTT2 data. Will give all data which need iOS app
public protocol VSTT2 {
    /// Temporary setter for activating and deactivating background access in positionKit
    func setBackgroundAccess(isActive: Bool)

    /// Method for initiate selected Store data
    func initiateStore(store: Store, floorLevel: Int)
}

public enum VSTT2Error: Error {
    case noAvailableStores
    case noAvailableMapData
}
