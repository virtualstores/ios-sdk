//
// INavigation
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Foundation
import ios_position_kit_sdk
import Combine
import VSFoundation
import CoreGraphics

public protocol INavigation {
    /// Flag for checking if sdk is active
    var isActive: Bool { get }
    
    /// Synchronize the position manager with  startPosition and startAngel
    func start(startPosition: CGPoint, startAngle: Double) throws
 
    /// Synchronize the position manager with a positioned code.
    func start(code: PositionedCode) throws

    /// Synchronize the position manager with a position, syncRotation and forceSync
    func syncPosition(position: ItemPosition, syncRotation: Bool, forceSync: Bool) throws
    
    /// Start the position with compass
    func compassStartNavigation(startPosition: CGPoint) throws
        
    /// Synchronize the position with compass
    func compassSyncPosition(position: ItemPosition) throws
    
    /// This will stop notifying the location publishers.
    func stop()
    
    /// Provide device start angle
    func prepareAngle()
}
