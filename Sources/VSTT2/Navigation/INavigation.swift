//
// INavigation
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Foundation
import VSPositionKit
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
    func start(startPosition: CGPoint, position: ItemPosition?) throws
        
    /// Synchronize the position with compass
    func syncPosition(position: ItemPosition, forceSync: Bool) throws

    func syncPosition(identifier: String, type: SyncTypeEnum, completion: @escaping (Result<Item?,Error>) -> ())
    
    /// This will stop notifying the location publishers.
    func stop()
    
    /// Provide device start angle
    func prepareAngle()
}

public enum SyncTypeEnum {
    case compass(forceSync: Bool)
    case normal(syncRotation: Bool)
}
