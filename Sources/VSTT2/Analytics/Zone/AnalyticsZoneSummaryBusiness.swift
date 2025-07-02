//
//  AnalyticsZoneSummaryBusiness.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-04-09.
//

import Foundation

class AnalyticsZoneSummaryBusiness {
  class ZoneTriggerGroup: Equatable {
    let enterEvent: TriggerEvent?
    var exitEvent: TriggerEvent?

    init(enterEvent: TriggerEvent?, exitEvent: TriggerEvent?) {
      self.enterEvent = enterEvent
      self.exitEvent = exitEvent
    }

    static func == (lhs: ZoneTriggerGroup, rhs: ZoneTriggerGroup) -> Bool {
      guard
        lhs.enterEvent?.eventType.getTrigger().zoneTrigger?.zoneId == rhs.enterEvent?.eventType.getTrigger().zoneTrigger?.zoneId,
        lhs.exitEvent?.eventType.getTrigger().zoneTrigger?.zoneId == rhs.exitEvent?.eventType.getTrigger().zoneTrigger?.zoneId
      else { return false }
      return true
    }
  }

  struct ZoneTriggerCounts {
    var totalEntryCount: Int
    var totalTime: Double
    var entryPointCounts: [String: ZoneCountsDTO.EntryPointCountsDTO]
  }

  struct ZoneCountsDTO: Codable {
    let entryCount: Int
    let duration: String // "00:25:00", "1.00:10:00"
    let entryPointCounts: [String: EntryPointCountsDTO]?
    struct EntryPointCountsDTO: Codable {
      var entryCount: Int
      var exitCount: Int
    }
  }

  var counts: [String: ZoneTriggerCounts] { zoneTriggerCounts }
  private var zoneTriggerCounts = [String: ZoneTriggerCounts]()
  private var insideZones = [ZoneTriggerGroup]()

  func onEnter(event: TriggerEvent) {
    insideZones.append(.init(enterEvent: event, exitEvent: nil))
  }

  func onExit(event: TriggerEvent) {
    insideZones.first(where: { $0.enterEvent?.eventType.getTrigger().zoneTrigger?.zoneId == event.eventType.getTrigger().zoneTrigger?.zoneId })?.exitEvent = event

    guard
      let group = insideZones.first(where: { $0.enterEvent?.eventType.getTrigger().zoneTrigger?.zoneId == event.eventType.getTrigger().zoneTrigger?.zoneId }),
      let enter = group.enterEvent,
      let exit = group.exitEvent
    else { return }
    insideZones.removeFirst(of: group)
    let timeInZone = exit.timestamp.timeIntervalSince(enter.timestamp)
    var triggerCounts = zoneTriggerCounts[enter.name, default: .init(totalEntryCount: 0, totalTime: 0, entryPointCounts: [:])]
    triggerCounts.totalTime += timeInZone
    triggerCounts.totalEntryCount += 1
    if let point = enter.eventType.getTrigger().zoneTrigger?.entryPoint {
      triggerCounts.entryPointCounts[point.id, default: .init(entryCount: 0, exitCount: 0)].entryCount += 1
    }
    if let point = exit.eventType.getTrigger().zoneTrigger?.entryPoint {
      triggerCounts.entryPointCounts[point.id, default: .init(entryCount: 0, exitCount: 0)].exitCount += 1
    }
    zoneTriggerCounts[enter.name] = triggerCounts
  }

  func popCurrentZoneSummary() -> [String: ZoneCountsDTO]? {
    // TODO: Guard for is not empty?
    guard !zoneTriggerCounts.isEmpty else { return nil }
    defer { zoneTriggerCounts.removeAll() }
    return convertToDTO(zoneSummary: zoneTriggerCounts)
  }

  func convertToDTO(zoneSummary: [String: ZoneTriggerCounts]) -> [String: ZoneCountsDTO] {
    zoneSummary.mapValues {
      return ZoneCountsDTO(
        entryCount: $0.totalEntryCount,
        duration: $0.totalTime.asAnalyticsDuration,
        entryPointCounts: $0.entryPointCounts.isEmpty ? nil : $0.entryPointCounts)
    }
  }

  func exitAllRemainingZones(timestamp: Date) {
    defer { insideZones.removeAll() }
    let events = insideZones.map { (group) -> TriggerEvent? in
      guard let enter = group.enterEvent, let trigger = enter.eventType.getTrigger().zoneTrigger else { return nil }
      return TriggerEvent(
        id: enter.id,
        rtlsOptionsId: enter.rtlsOptionsId,
        name: enter.name,
        description: enter.description,
        eventType: .zoneTrigger(.init(
          zoneId: trigger.zoneId,
          groupId: trigger.groupId,
          type: .exit,
          entryPoint: nil
        ))
      )
    }
    events
      .compactMap({ $0 })
      .forEach {
        onExit(event: $0)
    }
  }
}

extension Array where Element: Equatable {
  mutating func removeFirst(of element: Element) {
    guard let index = firstIndex(of: element) else { return }
    remove(at: index)
  }
}

extension Double {
  var asAnalyticsDuration: String {
    let days = Int(self) / 86400
    let hours = (Int(self) / 3600 % 24).formatNumber(decimals: 2)
    let minutes = (Int(self) / 60 % 60).formatNumber(decimals: 2)
    let seconds = (Int(self) % 60).formatNumber(decimals: 2)
    let microseconds = Int(self.truncatingRemainder(dividingBy: 1) * 1000).formatNumber(decimals: 3)

    return "\(days).\(hours):\(minutes):\(seconds).\(microseconds)"
  }
}

extension Int {
  func formatNumber(decimals: Int) -> String {
    String(format: "%0\(decimals)d", self)
  }
}
