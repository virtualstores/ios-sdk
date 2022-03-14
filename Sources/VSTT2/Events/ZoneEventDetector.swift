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
    var triggersAndEvents: [String: (event: TriggerEvent, triggerType: TriggerEvent.ZoneTrigger)] = [:]
    var inAndOut: InAndOutZone?
    
    public var eventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)

    private var zones: [Zone]?

    func setup(with zones: [Zone]) {
        self.zones = zones
    }
    
    func add(event: TriggerEvent) {
        events.append(event)
        updateInAndOut()
    }

    func remove(event: TriggerEvent) {
        events.removeAll(where: { $0.name == event.name })
        updateInAndOut()
    }

    func updateInAndOut() {
        var triggers: [InAndOutZone.Trigger] = []

        events.forEach { event in
            guard let trigger = event.eventType.getTrigger().zoneTrigger, let zone = zones?.first(where: { $0.name == trigger.zoneId }) else { return }
            triggers.append(InAndOutZone.Trigger(id: trigger.zoneId, polygon: zone.points))
            triggersAndEvents[trigger.zoneId] = (event, trigger)
        }

        inAndOut = InAndOutZone(triggers: triggers)
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

    private func postEvent(event: TriggerEvent, position: CGPoint) {
        event.updateEventData(for: position, timestamp: Date())

        guard event.userPosition != .zero/*, !event.hasBeenTriggered*/ else { return }

        //event.updateEventStatus(hasBeenTriggered: true)
        self.eventPublisher.send(event)
    }
}

extension ZoneEventDetector: InAndOutZoneDelegate {
    func onEnter(trigger: InAndOutZone.Trigger, position: CGPoint) {
        guard let tuple = triggersAndEvents[trigger.id], tuple.triggerType.type == .enter else { return }
        self.postEvent(event: tuple.event, position: position)
    }

    func onExit(trigger: InAndOutZone.Trigger, position: CGPoint) {
      guard let tuple = triggersAndEvents[trigger.id], tuple.triggerType.type == .exit else { return }
      self.postEvent(event: tuple.event, position: position)
    }
}
