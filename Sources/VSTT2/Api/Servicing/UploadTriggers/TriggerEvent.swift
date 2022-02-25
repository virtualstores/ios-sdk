//
// TriggerEvent
// VSTT2
//
// Created by Hripsime on 2022-02-23
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics

public class TriggerEvent {
  public let rtlsOptionsId: String
  public let name: String
  public let timestamp: Date
  public let userPosition: CGPoint
  public let appTrigger: AppTrigger?
  public let coordinateTrigger: CoordinateTrigger?
  public let shelfTrigger: ShelfTrigger?
  public let zoneTrigger: ZoneTrigger?
  public var tags: [String: String]
  public var metaData: [String: String]

  init(
    rtlsOptionsId: String,
    name: String,
    timestamp: Date,
    userPosition: CGPoint,
    appTrigger: AppTrigger? = nil,
    coordinateTrigger: CoordinateTrigger? = nil,
    shelfTrigger: ShelfTrigger? = nil,
    zoneTrigger: ZoneTrigger? = nil,
    tags: [String: String] = [:],
    metaData: [String: String] = [:]
  ) {
    self.rtlsOptionsId = rtlsOptionsId
    self.name = name
    self.timestamp = timestamp
    self.userPosition = userPosition
    self.appTrigger = appTrigger
    self.coordinateTrigger = coordinateTrigger
    self.shelfTrigger = shelfTrigger
    self.zoneTrigger = zoneTrigger
    self.tags = tags
    self.metaData = metaData
  }

  public func add(tags: [String: String]) {
    tags.forEach { (key, value) in
      self.tags[key] = value
    }
  }

  public func add(metaData: [String: String]) {
    metaData.forEach { (key, value) in
      self.metaData[key] = value
    }
  }

  public struct AppTrigger {
    public let event: String

    var asPostTrigger: PostTriggerEventRequest.AppTrigger {
      PostTriggerEventRequest.AppTrigger(event: event)
    }
  }

  public struct CoordinateTrigger {
    public let point: CGPoint
    public let radius: Double

    var asPostTrigger: PostTriggerEventRequest.CoordinateTrigger {
      PostTriggerEventRequest.CoordinateTrigger(point: point, radius: radius)
    }
  }

  public struct ShelfTrigger {
    public let shelfGroupId: Int?
    public let shelfId: Int?
    public let shelfTierId: Int?
    
    var asPostTrigger: PostTriggerEventRequest.ShelfTrigger {
      PostTriggerEventRequest.ShelfTrigger(shelfGroupId: shelfGroupId, shelfId: shelfId, shelfTierId: shelfTierId)
    }
  }

  public struct ZoneTrigger {
    public let zoneId: String
    public let groupId: String
    public let type: ZoneType

    var asPostTrigger: PostTriggerEventRequest.ZoneTrigger {
      PostTriggerEventRequest.ZoneTrigger(zoneId: zoneId, groupId: groupId, type: PostTriggerEventRequest.ZoneTrigger.ZoneType.init(rawValue: type.rawValue) ?? .enter)
    }

    public enum ZoneType: String {
      case enter = "ENTER"
      case exit = "EXIT"
    }
  }
}

public struct ScanEvent {
  public let barcode: String
  public let shelfId: Int?
  public let point: CGPoint?
  public let timestamp: Int64
  public let type: ShelfType

  public init(barcode: String, shelfId: Int?, point: CGPoint?, timestamp: Int64, type: ShelfType) {
    self.barcode = barcode
    self.shelfId = shelfId
    self.point = point
    self.timestamp = timestamp
    self.type = type
  }

  public enum ShelfType: Int {
    case unknown = 0
    case shelf = 1
  }
}