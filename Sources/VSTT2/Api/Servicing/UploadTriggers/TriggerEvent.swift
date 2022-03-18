//
// TriggerEvent
// VSTT2
//
// Created by Hripsime on 2022-02-23
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import VSFoundation

public class TriggerEvent {
    public let rtlsOptionsId: String
    public let name: String
    public let description: String
    public private(set) var timestamp: Date
    public private(set) var userPosition: CGPoint
    public var eventType: EventType
    public private(set) var tags: [String: String]
    public private(set) var metaData: [String: String]
    public private(set) var hasBeenTriggered: Bool
    
    public init(
        rtlsOptionsId: String,
        name: String,
        description: String,
        timestamp: Date = Date(),
        userPosition: CGPoint = .zero,
        eventType: EventType,
        tags: [String: String] = [:],
        metaData: [String: String] = [:],
        hasBeenTriggered: Bool = false
    ) {
        self.rtlsOptionsId = rtlsOptionsId
        self.name = name
        self.description = description
        self.timestamp = timestamp
        self.userPosition = userPosition
        self.eventType = eventType
        self.tags = tags
        self.metaData = metaData
        self.hasBeenTriggered = hasBeenTriggered
    }
    
    func updateEventData(for userPosition: CGPoint, timestamp: Date) {
        guard self.userPosition == .zero else { return }
        
        self.userPosition = userPosition
        self.timestamp = timestamp
    }
    
    public func updateEventStatus(hasBeenTriggered: Bool = false) {
        self.hasBeenTriggered = hasBeenTriggered
    }
    
    public enum EventType {
        case appTrigger(AppTrigger)
        case coordinateTrigger(CoordinateTrigger)
        case shelfTrigger(ShelfTrigger)
        case zoneTrigger(ZoneTrigger)
        
        func getTrigger() -> (appTrigger: AppTrigger?, coordinateTrigger: CoordinateTrigger?, shelfTrigger: ShelfTrigger?, zoneTrigger: ZoneTrigger?) {
            
            var app: AppTrigger?
            var coordinate: CoordinateTrigger?
            var shelf: ShelfTrigger?
            var zone: ZoneTrigger?
            switch self {
            case .appTrigger(let appTrigger): app = appTrigger
            case .coordinateTrigger(let coordinateTrigger): coordinate = coordinateTrigger
            case .shelfTrigger(let shefTrigger): shelf = shefTrigger
            case .zoneTrigger(let zoneTrigger): zone = zoneTrigger
            }
            
            return (appTrigger: app, coordinateTrigger: coordinate, shelfTrigger: shelf, zoneTrigger: zone)
        }
    }

    public struct DefaultTags {
        public let messageShown: String = "messageShown"
    }

    public struct DefaultMetaData {
        public let id: String = "@id"
        public let title: String = "@title"
        public let body: String = "@body"
        public let imageUrl: String = "@imageUrl"
        public let type: String = "@type"

        public enum MessageType: String {
            case small = "SMALL"
            case large = "LARGE"
        }
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
        
        public init(event: String) {
            self.event = event
        }
        
        var asPostTrigger: PostTriggerEventRequest.AppTrigger {
            PostTriggerEventRequest.AppTrigger(event: event)
        }
    }
    
    public struct CoordinateTrigger {
        public let point: CGPoint
        public let radius: Double
        
        public init(point: CGPoint, radius: Double) {
            self.point = point
            self.radius = radius
        }
        
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

public extension TriggerEvent {
    var toMessageShown: TriggerEvent? {
        let defaultMetaData = DefaultMetaData()
        guard let id = self.metaData[defaultMetaData.id] else { return nil }
        let defaultTags = TriggerEvent.DefaultTags()
      var tags: [String : String] = [:]
        self.tags.forEach { (key, value) in
            tags[key] = value
        }
        tags = [ defaultTags.messageShown : id ]
        let event = TriggerEvent(
            rtlsOptionsId: self.rtlsOptionsId,
            name: self.name,
            description: self.description,
            timestamp: self.timestamp,
            userPosition: self.userPosition,
            eventType: .appTrigger(TriggerEvent.AppTrigger(event: self.name)),
            tags: tags,
            metaData: self.metaData,
            hasBeenTriggered: self.hasBeenTriggered
        )
        return event
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
