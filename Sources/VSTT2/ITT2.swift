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
import CoreGraphics

///
/// Interface for TT2 SDK.
///  1- To get the SDK ready to work first Call initialize method. This will prepare the SDK for  all other purposes.
///  2- To initialize your store, call initStore
public protocol ITT2 {
    var initialized: Bool { get }
    /// Navigation manager
    var navigation: Navigation { get }
    
    /// Analytics manager
    var analytics: TT2AnalyticsManager { get }
    
    /// Floor manager
    var floor: VSTT2FloorManager { get }
    
    /// Position manager
    var position: Position { get }

    /// Event Manager
    var events: TT2EventManager { get }
    
    /// User Settings manager
//    var userSettings: UserSettings { get }

    var user: UserController { get }

    /// Recording manager
    var recording: IRecordingManager { get }
    
    /// Active store
    var activeStore: TT2Store? { get }
    
    /// List of active stores
    var activeStores: [TT2Store] { get }

    var activeFloor: RtlsOptions? { get }
    
    /// List of available stores
    var stores: [TT2Store] { get }

    var mapZonesTree: Tree? { get }

    /// Method for initialize TT2 for specific client
    func initialize(clientId: Int64, positionKitParams: ParameterPackage, completion: @escaping (Error?) -> ())
    
    /// Method for initiate selected Store data
    func initiate(store: TT2Store, completion: @escaping (Error?) -> ())

    /// Convenience method to initiate selected Store data
    func initiate(storeId: Int64, completion: @escaping (Error?) -> Void)
    
    /// Setup the Map
    func set(map: IMapController)

    /// Setup the WiFi
    func set(wifi: IWiFiController)

    /// Settings for TT2
    func set(automaticActivationOfUserMark: Bool)
    
    /// Methode for creating MapData for MapSdk
    func getMapData() -> MapData?

    func stop()

    func setActiveFloor(rtls: RtlsOptions)
}

public enum VSTT2Error: Error {
    case noAvailableStores
    case noAvailableMapData
    case missingData
}
