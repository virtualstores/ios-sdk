//
// VSTT2Floor
// VSTT2
//
// Created by Hripsime on 2022-02-22
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine

public protocol VSTT2Floor {
    /// Active Floor data
    var activeFloor: RtlsOptions? { get }
    
    /// All available floors which user can have
    var floors: [RtlsOptions] { get }
    
    /// PathFinder for floor
    var pathFinder: VSPathFinder? { get }
    
    /// MapFence data for floor
    var mapFence: MapFence? { get }
    
    /// Zones  in floor
    var zones: Data? { get }
    
    /// Messages  for showing in floor
    var messages: [Message]? { get }
    
    var mapDataPublisher: CurrentValueSubject<(zones: [MapZone]?, points: [MapZonePoint]?), Never> { get }

    /// Methode for setup Active Floor with options
    func setActiveFloor(with rtlsOptions: RtlsOptions)
    
    /// Methode for setup Active Floor with floorLevel
    func setActiveFloor(with floorLevel: Int)

    /// update Analytics when floor changed
    func updateFloorInAnalyticsController()
}
