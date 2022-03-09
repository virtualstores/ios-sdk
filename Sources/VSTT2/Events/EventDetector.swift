//
// EventDetector
// VSTT2
//
// Created by Hripsime on 2022-01-25
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import VSFoundation
import Combine

protocol EventDetector {
    /// List of events which can have each event type
    var events: [TriggerEvent] { get }
    
    /// Zoone event publisher for sending data to the app
    var eventPublisher: CurrentValueSubject<TriggerEvent?, Never> { get }

    /// Setup methode for using zone list for checking user zone place
    func setup(with zones: [Zone])
    
    /// Methode which will receave user position change each time
    func onNewPosition(currentPosition: CGPoint)
    
    /// Methode for being able to addEvent
    func add(event: TriggerEvent)

    /// Methode for being able to removeEvent
    func remove(event: TriggerEvent)
}
