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
    var triggersAndEvents: [String: (event: TriggerEvent, triggerType: TriggerEvent.CoordinateTrigger)] = [:]
    var inAndOut: InAndOutRadius?
    
    func add(event: TriggerEvent) {
        events.append(event)
        updateInAndOut()
    }
    
    func remove(event: TriggerEvent) {
        events.removeAll(where: { $0.name == event.name })
        updateInAndOut()
    }

    func updateInAndOut() {
        var triggers: [InAndOutRadius.Trigger] = []

        events.forEach { event in
            guard let trigger = event.eventType.getTrigger().coordinateTrigger else { return }
            triggers.append(InAndOutRadius.Trigger(id: event.name, centerPoint: trigger.point, radius: trigger.radius))
            triggersAndEvents[event.name] = (event, trigger)
        }

        inAndOut = InAndOutRadius(triggers: triggers)
        inAndOut?.add(delegate: self)
    }

    var count = 0
    var threshhold = 5
    func onNewPosition(currentPosition: CGPoint) {
        count += 1
        guard count >= threshhold else { return }
        count = 0
        inAndOut?.onNewPosition(currentPosition: currentPosition)
    }
    
    func setup(with zones: [Zone]) { }

    private func postEvent(event: TriggerEvent, position: CGPoint) {
        event.updateEventData(for: position, timestamp: Date())
        guard event.userPosition != .zero else { return }

        //event.updateEventStatus(hasBeenTriggered: true)
        eventPublisher.send(event)
    }
}

extension CoordinateEventDetector: InAndOutRadiusDelegate {
    func onEnter(trigger: InAndOutRadius.Trigger, position: CGPoint) {
        guard let tuple = triggersAndEvents[trigger.id], tuple.triggerType.type == .enter else { return }
        self.postEvent(event: tuple.event, position: position)
    }

    func onExit(trigger: InAndOutRadius.Trigger, position: CGPoint) {
        guard let tuple = triggersAndEvents[trigger.id], tuple.triggerType.type == .exit else { return }
        self.postEvent(event: tuple.event, position: position)
    }
}
