//
// VSTT2
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021
import Foundation
import Combine
import Foundation
import VSFoundation

///
/// Interface for TT2 SDK.
///  1- To get the SDK ready to work first Call initialize method. This will prepare the SDK for  all other purposes.
///  2- To initialize your store, call initStore
///  3- When your store is ready, you are ready to initialize a floor.
public protocol VSTT2 {
    /// Temporary setter for activating and deactivating background access in positionKit
    func setBackgroundAccess(isActive: Bool)

    /// Method for initiate selected Store data
    func initiateStore(store: Store)
    
    /// Methode for creating MapData for MapSdk
    func createMapData(rtlsOptions: RtlsOptions, mapFence: MapFence) -> MapData? 
}

public enum VSTT2Error: Error {
    case noAvailableStores
    case noAvailableMapData
}
