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
    var eventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
    
    var events: [TriggerEvent] = []
    
    func add(event: TriggerEvent) {
        events.append(event)
    }
    
    func remove(event: TriggerEvent) {
        events.removeAll(where: { $0.name == event.name })
    }
    
    func onNewPosition(currentPosition: CGPoint) {
        events.forEach { event in
            guard let coordinateTrigger = event.eventType.getTrigger().coordinateTrigger else { return }
            
            let scale = 50.0
            let pointInside = sqrt(pow(currentPosition.x - Double(coordinateTrigger.point.x), 2.0) + pow(currentPosition.y - Double(coordinateTrigger.point.y), 2.0)) * scale
            if pointInside < coordinateTrigger.radius, !event.hasBeenTriggered {
                event.updateEventData(for: currentPosition, timestamp: Date())
                guard event.userPosition != .zero else { return }
                
                event.updateEventStatus(hasBeenTriggered: true)
                eventPublisher.send(event)
            }
        }
    }
    
    func setup(with zones: [Zone]) { }
}
