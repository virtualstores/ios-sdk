//
// TT2Event
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import CoreGraphics

/// Event finterface. Will give all data which need iOS app for Events
public protocol TT2Event {
    /// Publisher for receiving triggered message information
    var messageEventPublisher: CurrentValueSubject<TriggerEvent?, Never> { get }

    /// Publisher for receiving pointOfInteres information
    var pointOfInterestPublisher: CurrentValueSubject<PointOfInterest?, Never> { get }
    
    /// Methode for being able to addEvent
    func addEvent(with id: String, event: TriggerEvent)

    /// Methode for being able to removeEvent
    func removeEvent(with id: String)
    
    /// Methode for receaving new position, for checking  events for that position
    func onNewPosition(currentPosition: CGPoint)
}

