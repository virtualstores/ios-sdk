//
//  EventDetector.swift
//
//
//  Created by Théodore Roos on 2024-05-16.
//

import Foundation
import Combine
import VSFoundation

class EventDetector {
  @Inject var decideWhichTriggerEvent: DecideWhichTriggerEventToDisplayUseCase
  var events: [TriggerEvent] = []
  var eventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)

  private var inAndOut: InAndOut?
  private var zones: [Zone]?
  private var triggersAndEvents: [String: (triggerType: TriggerEvent.TriggerType, event: TriggerEvent)] = [:]
  private var positionCount = 0
  private var positionThreshhold = 5
}

private extension EventDetector {
  func updateInAndOut() {
    var triggers = [IInAndOutTrigger]()
    events.forEach { (event) in
      switch event.eventType {
      case .appTrigger(_): break
      case .coordinateTrigger(let trigger):
        triggers.append(InAndOut.Radius(id: event.id, centerPoint: trigger.point, radius: trigger.radius))
      case .shelfTrigger(_): break
      case .zoneTrigger(let trigger):
        // TODO: Filter on name?
        guard let zone = zones?.first(where: { $0.name == trigger.zoneId }) else { return }
        triggers.append(InAndOut.Zone(id: event.id, zoneId: zone.id, polygon: zone.extendedPoints ?? zone.points))
        triggersAndEvents[event.id] = (trigger.type, event)
      }
    }
    inAndOut = .init(triggers: triggers)
    inAndOut?.add(delegate: self)
  }

  func postEvent(event: TriggerEvent, position: CGPoint) {
    event.updateEventData(for: position, timestamp: Date())
    guard event.userPosition != .zero/*, !event.hasBeenTriggered*/ else { return }
    eventPublisher.send(event)
  }
}

extension EventDetector: IEventDetector {
  func setup(with zones: [Zone]) {
    self.zones = zones
  }

  func on(new position: VPSOutputSignal.Position) {
    positionCount += 1
    guard positionCount >= positionThreshhold else { return }
    positionCount = 0
    if position.trustedPosition {
      inAndOut?.on(new: position.point)
    }
  }

  func add(event: TriggerEvent) {
    events.append(event)
    updateInAndOut()
  }

  func set(events: [TriggerEvent]) {
    self.events = events
    updateInAndOut()
  }

  func remove(event: TriggerEvent) {
    events.removeAll(where: { $0.name == event.name })
    updateInAndOut()
  }
}

extension EventDetector: IInAndOutDelegate {
  func onEnter(trigger: IInAndOutTrigger, position: CGPoint) {
    //handle(triggers: [trigger], position: position, type: .enter)
  }

  func onExit(trigger: IInAndOutTrigger, position: CGPoint) {
    //handle(triggers: [trigger], position: position, type: .exit)
  }

  func onEnter(triggers: [IInAndOutTrigger], position: CGPoint) {
    handle(triggers: triggers, position: position, type: .enter)
  }

  func onExit(triggers: [IInAndOutTrigger], position: CGPoint) {
    handle(triggers: triggers, position: position, type: .exit)
  }

  func handle(triggers: [IInAndOutTrigger], position: CGPoint, type: TriggerEvent.TriggerType) {
    let events = triggersAndEvents
      .filter({ $0.value.triggerType == type })
      .filter({ (triggerAndEvent) in triggers.contains(where: { $0.id == triggerAndEvent.key }) })
      .map({ $0.value.event })
    guard
      !events.isEmpty,
      let event = decideWhichTriggerEvent.invoke(triggerEvents: events)
    else { return }
    postEvent(event: event, position: position)
  }
}
