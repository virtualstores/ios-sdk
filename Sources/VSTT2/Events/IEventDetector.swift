//
// IEventDetector
// VSTT2
//
// Created by Hripsime on 2022-01-25
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import VSFoundation
import Combine

protocol IEventDetector {
    /// List of events which can have each event type
    var events: [TriggerEvent] { get }
    
    /// Zone event publisher for sending data to the app
    var eventPublisher: CurrentValueSubject<TriggerEvent?, Never> { get }

    /// Setup method for using zone list for checking user zone place
    func setup(with zones: [Zone])
    
    /// Method which will receave user position change each time
    func on(new position: VPSOutputSignal.Position)
    
    /// Methode for being able to addEvent
    func add(event: TriggerEvent)

    /// Methode for being able to removeEvent
    func remove(event: TriggerEvent)
}
