//
// TT2EventManager
// VSTT2
//
// Created by Hripsime on 2022-01-25
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import VSFoundation
import Combine

internal class CoordinateEventDetector: EventDetector {
    var zooneEventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
    
    var events: [TriggerEvent] = []

    func add(event: TriggerEvent) {
        events.append(event)
    }

    func remove(event: TriggerEvent) {
        events.removeAll(where: { $0.name == event.name })
    }
    
    func onNewPosition(currentPosition: CGPoint) { }
    
    func setup(with zones: [Zone]) { }
}
