//
//  AnalyticsZoneSummaryBusiness.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-04-09.
//

class AnalyticsZoneSummaryBusiness {
  struct ZoneTriggerGroup: Equatable {
    let enterEvent: TriggerEvent?
    var exitEvent: TriggerEvent?

    static func == (lhs: ZoneTriggerGroup, rhs: ZoneTriggerGroup) -> Bool {
      guard
        lhs.enterEvent?.eventType.getTrigger().zoneTrigger?.zoneId == rhs.enterEvent?.eventType.getTrigger().zoneTrigger?.zoneId,
        lhs.exitEvent?.eventType.getTrigger().zoneTrigger?.zoneId == rhs.exitEvent?.eventType.getTrigger().zoneTrigger?.zoneId
      else { return false }
      return true
    }
  }

  struct ZoneTriggerCounts {
    let totalEntryCount: Int
    let totalTime: Double
    let entryPointCounts: [String: TriggerEvent.ZoneTrigger.EntryPoint]
  }

  private var insideZones = [ZoneTriggerGroup]()

  func onEnter(event: TriggerEvent) {
    insideZones.append(.init(enterEvent: event, exitEvent: nil))
  }

  func onExit(event: TriggerEvent) {
    guard var group = insideZones.first(where: { $0.enterEvent?.eventType.getTrigger().zoneTrigger?.zoneId == event.eventType.getTrigger().zoneTrigger?.zoneId }) else { return }

    group.exitEvent = event

    insideZones.removeAll(where: { $0 == group })
    insideZones.removeFirst(of: group)
  }
}

extension Array where Element: Equatable {
  mutating func removeFirst(of element: Element) {
    guard let index = firstIndex(of: element) else { return }
    remove(at: index)
  }
}
