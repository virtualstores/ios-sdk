//
// ITT2
// ITT2
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
public protocol ITT2 {
    /// Navigation manager
    var navigation: Navigation { get }
    
    /// Analytics manager
    var analytics: TT2AnalyticsManager { get }
    
    /// Floor manager
    var floor: VSTT2FloorManager { get }
    
    /// Position manager
    var position: Position { get }
    
    /// Method for initialize TT2 for specific client
    func initialize(with apiUrl: String, apiKey: String, clientId: Int64, completion: @escaping (StoresList) -> ())
    
    /// Method for initiate selected Store data
    func initiateStore(store: Store, completion: @escaping () -> ())
    
    /// Temporary setter for activating and deactivating background access in positionKit
    func setBackgroundAccess(isActive: Bool)
    
    /// Methode for creating MapData for MapSdk
    func getMapData() -> MapData? 
}

public enum VSTT2Error: Error {
    case noAvailableStores
    case noAvailableMapData
}
