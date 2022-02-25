//
// ZoneEventDetector
// VSTT2
//
// Created by Hripsime on 2022-01-25
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import VSFoundation
import Combine

internal class ZoneEventDetector: EventDetector {
    var events: [TriggerEvent] = []
    
    public var zooneEventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)

    private var zoones: [Zone]?

    func setup(with zones: [Zone]) {
        self.zoones = zones
    }
    
    func add(event: TriggerEvent) {
        events.append(event)
    }

    func remove(event: TriggerEvent) {
        events.removeAll(where: { $0.name == event.name })
    }
    
    func onNewPosition(currentPosition: CGPoint) {
        for event in events {
            guard let zones = self.zoones?.all(where: { $0.contains(point: currentPosition)}) else { return }
            
            for zone in zones {
                if let appEvent = event.eventType?.getTrigger().appTrigger, appEvent.zoneIds.contains(zone.name) {
                    self.zooneEventPublisher.send(event)
                }
            }
        }
    }
}
