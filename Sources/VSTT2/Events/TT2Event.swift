//
// TT2Event
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import CoreGraphics

/// Event interface. Will give all data which need iOS app for Events
public protocol TT2Event {
    /// Publisher for receiving triggered message information
    var messageEventPublisher: CurrentValueSubject<TriggerEvent?, Never> { get }

    /// Publisher for receiving pointOfInteres information
    var pointOfInterestPublisher: CurrentValueSubject<PointOfInterest?, Never> { get }
    
    /// Method for being able to add event
    func add(event: TriggerEvent)

    /// Method for being able to remove event
    func remove(event: TriggerEvent)

    /// Method for being able to remove event
    func remove(event id: String)
    
    /// Method for receiving new position, for checking  events for that position
    func onNewPosition(currentPosition: CGPoint)
}

