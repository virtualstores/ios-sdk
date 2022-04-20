//
//  TriggerEventDto.swift
//  
//
//  Created by Théodore Roos on 2022-04-11.
//

import Foundation
import CoreGraphics
import VSFoundation

struct TriggerEventDto: Codable {
  let id: Int
  let name: String
  let triggerType: TriggerType
  let zonesTrigger: [String : [ZonesTrigger]]?
  let coordinatesTrigger: [String : [CoordinateTrigger]]?
  let tags: [String : String]
  let metadata: [String : String]

  enum TriggerType: String, Codable {
    case zones = "ZONES"
    case coordinates = "COORDINATES"
    case enter = "ENTER"
    case exit = "EXIT"
  }

  struct ZonesTrigger: Codable {
    let id: String
    let type: TriggerType

    var asTriggerEventZone: TriggerEvent.ZoneTrigger {
      TriggerEvent.ZoneTrigger(zoneId: id, groupId: UUID().uuidString.uppercased(), type: TriggerEvent.TriggerType(rawValue: type.rawValue) ?? .enter)
    }
  }

  struct CoordinateTrigger: Codable {
    let x: Double
    let y: Double
    let radius: Double
    let rtlsOptionsId: Int64
    let type: TriggerType

    var asTriggerEventCoordinate: TriggerEvent.CoordinateTrigger {
      TriggerEvent.CoordinateTrigger(point: CGPoint(x: x, y: y), radius: radius, type: TriggerEvent.TriggerType(rawValue: type.rawValue) ?? .enter)
    }
  }
}

extension TriggerEventDto {
  func toTriggerEvent(mapZones: [Zone]) -> [TriggerEvent] {
    guard let name = tags["@message.name"] else { return [] }
    var events: [TriggerEvent] = []
    if let coordinates = coordinatesTrigger?.values.flatMap({ $0 }) {
      coordinates.forEach { events.append(TriggerEvent(rtlsOptionsId: $0.rtlsOptionsId, name: name, description: "", eventType: .coordinateTrigger($0.asTriggerEventCoordinate), tags: tags, metaData: metadata)) }
    } else if let zones = zonesTrigger?.values.flatMap({ $0 }) {
      zones.forEach { zone in
        guard let id = mapZones.first(where: { $0.name == zone.id })?.floorLevelId else { return }
        events.append(TriggerEvent(rtlsOptionsId: id, name: name, description: "", eventType: .zoneTrigger(zone.asTriggerEventZone), tags: tags, metaData: metadata))
      }
    }
    return events
  }
}
