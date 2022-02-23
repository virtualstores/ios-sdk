//
// TT2Zone
// VSTT2
//
// Created by Hripsime on 2022-02-22
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import Combine

public protocol TT2Zone {
    /// Publishes the zone entered event
    var zoneEnteredPublisher: CurrentValueSubject<TriggerEvent?, Never> { get }
    
    /// Publishes the zone exited event
    var zoneExitedPublisher: CurrentValueSubject<TriggerEvent?, Never> { get }

    /// Methode for receaving new position, for checking on which zone is it
    func onNewPosition(currentPosition: CGPoint)
    
    /// Methode for stopping active zone entering
    func stopped(currentPosition: CGPoint)
}
