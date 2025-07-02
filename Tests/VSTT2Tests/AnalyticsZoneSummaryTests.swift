//
//  AnalyticsZoneSummaryTests.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-06-25.
//

import XCTest
@testable import VSTT2

final class AnalyticsZoneSummaryTests: XCTestCase {
  private let business = AnalyticsZoneSummaryBusiness()
  func test_new_analytics_zone_business() {
    var numberOfExpectedEntryCounts = [
      "Toalett" : 2,
      "Köket-Extended" : 4,
      "TrafficArea1" : 3,
      "Köket" : 1,
      "Hallen" : 1,
      "Entrance Exposure point 1" : 1
    ]

    var numberOfExpectedEntryPointEnterCount = [
      "4f03f1af739542489d1d1f8d7b153558" : 2,
      "45ac6ad365c74fd3ad33d00f047ea94b" : 1,
      "e0ea5485f01c4d29ba3abd6875fce38a" : 1,
      "3b6eefeab44749038446af9457bc3d12" : 1
    ]

    var numberOfExpectedEntryPointExitCount = [
      "4f03f1af739542489d1d1f8d7b153558" : 2,
      "45ac6ad365c74fd3ad33d00f047ea94b" : 0,
      "e0ea5485f01c4d29ba3abd6875fce38a" : 2,
      "3b6eefeab44749038446af9457bc3d12" : 0
    ]

    let events = ZonesTestData().zoneEnterExitEvents
    let stopTime = events.last!.timestamp + 5

    events.forEach {
      guard let trigger = $0.eventType.getTrigger().zoneTrigger else { return }
      switch trigger.type {
      case .enter:
        business.onEnter(event: $0)
      case .exit:
        business.onExit(event: $0)
      }
    }
    business.exitAllRemainingZones(timestamp: stopTime)
    print()
    business.counts.forEach {
      print("\($0.key) : Time \($0.value.totalTime.asAnalyticsDuration), Entries \($0.value.totalEntryCount)")
      $0.value.entryPointCounts.forEach { t, u in
        print("\(t) Enter: \(u.entryCount), Exit: \(u.exitCount)")
      }
      print()
    }

    business.counts.forEach { (zoneName, u) in
      if let ec = numberOfExpectedEntryCounts[zoneName] {
        XCTAssertEqual(ec, u.totalEntryCount)
        numberOfExpectedEntryCounts.removeValue(forKey: zoneName)
      } else {
        XCTAssert(false)
      }

      u.entryPointCounts.forEach { (t, u) in
        if let expected = numberOfExpectedEntryPointEnterCount[t] {
          XCTAssertEqual(expected, u.entryCount)
        } else {
          print("Unexpected enter entryPoint: \(t) in zone: \(zoneName)")
          XCTAssert(false)
        }
        print()
        if let expected = numberOfExpectedEntryPointExitCount[t] {
          XCTAssertEqual(expected, u.exitCount)
        } else {
          print("Unexpected exit entryPoint: \(t) in zone: \(zoneName)")
          XCTAssert(false)
        }
        numberOfExpectedEntryPointEnterCount.removeValue(forKey: t)
        numberOfExpectedEntryPointExitCount.removeValue(forKey: t)
      }
    }

    XCTAssert(numberOfExpectedEntryCounts.isEmpty)
    XCTAssert(numberOfExpectedEntryPointEnterCount.isEmpty)
    XCTAssert(numberOfExpectedEntryPointExitCount.isEmpty)
  }


  func test_zone_business_pop_summary_for_batch_requests() {
    let events = ZonesTestData().zoneEnterExitEvents
    let stopTime = events.last!.timestamp + 5

    var counter = 0
    events.forEach { (event) in
      counter += 1
      guard let trigger = event.eventType.getTrigger().zoneTrigger else { return }
      switch trigger.type {
      case .enter:
        business.onEnter(event: event)
      case .exit:
        business.onExit(event: event)
      }
      if counter >= 3 {
        counter = 0
        print("Pop result 1:")
        business.popCurrentZoneSummary()?.forEach {
          print("\($0.key) : Time \($0.value.duration), Entries \($0.value.entryCount)")
          $0.value.entryPointCounts?.forEach { (t, u) in
            print("\(t): Enter=\(u.entryCount), Exit=\(u.exitCount)")
          }
          print()
        }
        XCTAssert(business.counts.isEmpty)
      }
    }

    business.exitAllRemainingZones(timestamp: stopTime)

    print("Pop result 2:")
    business.popCurrentZoneSummary()?.forEach {
      print("\($0.key) : Time \($0.value.duration), Entries \($0.value.entryCount)")
      $0.value.entryPointCounts?.forEach { (t, u) in
        print("\(t): Enter=\(u.entryCount), Exit=\(u.exitCount)")
      }
      print()
    }
    XCTAssert(business.counts.isEmpty)
  }
}

struct ZonesTestData {
  let zoneEnterExitEvents: [TriggerEvent] = [
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Toalett",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "7dd4330473a859989df4c95bbbead890",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350580986 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Toalett",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "7dd4330473a859989df4c95bbbead890",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: .init(line: [], id: "e0ea5485f01c4d29ba3abd6875fce38a")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350588991 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket-Extended",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "c50aed46487480389834b1a8c14ca9b4",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350591073 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket-Extended",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "c50aed46487480389834b1a8c14ca9b4",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350596761 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "TrafficArea1",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "4ed8f3ce1dcb7dacb1bbde63a83932bf",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: .init(line: [], id: "4f03f1af739542489d1d1f8d7b153558")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350599751 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "TrafficArea1",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "4ed8f3ce1dcb7dacb1bbde63a83932bf",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350600652 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "TrafficArea1",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "4ed8f3ce1dcb7dacb1bbde63a83932bf",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: .init(line: [], id: "45ac6ad365c74fd3ad33d00f047ea94b")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350615084 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "TrafficArea1",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "4ed8f3ce1dcb7dacb1bbde63a83932bf",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: .init(line: [], id: "4f03f1af739542489d1d1f8d7b153558")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350618935 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket-Extended",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "c50aed46487480389834b1a8c14ca9b4",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350625858 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "ab6963a49841988b708bc587e966fc03",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350627939 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "ab6963a49841988b708bc587e966fc03",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350629769 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket-Extended",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "c50aed46487480389834b1a8c14ca9b4",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350644434 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Toalett",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "7dd4330473a859989df4c95bbbead890",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: .init(line: [], id: "e0ea5485f01c4d29ba3abd6875fce38a")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350648627 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Toalett",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "7dd4330473a859989df4c95bbbead890",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: .init(line: [], id: "e0ea5485f01c4d29ba3abd6875fce38a")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350657029 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket-Extended",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "c50aed46487480389834b1a8c14ca9b4",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350659139 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket-Extended",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "c50aed46487480389834b1a8c14ca9b4",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350665164 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "TrafficArea1",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "4ed8f3ce1dcb7dacb1bbde63a83932bf",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: .init(line: [], id: "4f03f1af739542489d1d1f8d7b153558")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350668742 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "TrafficArea1",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "4ed8f3ce1dcb7dacb1bbde63a83932bf",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: .init(line: [], id: "4f03f1af739542489d1d1f8d7b153558")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350679251 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket-Extended",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "c50aed46487480389834b1a8c14ca9b4",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350682875 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Köket-Extended",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "c50aed46487480389834b1a8c14ca9b4",
        groupId: UUID().uuidString.uppercased(),
        type: .exit,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350691857 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Hallen",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "2b61e3dda9cb8e74ff16d089081dbf17",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: .init(line: [], id: "3b6eefeab44749038446af9457bc3d12")
      )),
      timestamp: .init(timeIntervalSince1970: 1741350695134 / 1000)
    ),
    .init(
      id: UUID().uuidString,
      rtlsOptionsId: 66,
      name: "Entrance Exposure point 1",
      description: "No desc",
      eventType: .zoneTrigger(.init(
        zoneId: "44ce6e99aa2e9995ea56488b05e9966f",
        groupId: UUID().uuidString.uppercased(),
        type: .enter,
        entryPoint: nil
      )),
      timestamp: .init(timeIntervalSince1970: 1741350695137 / 1000)
    ),
  ]
}
