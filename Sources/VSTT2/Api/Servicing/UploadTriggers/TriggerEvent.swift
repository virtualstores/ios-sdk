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
    public let rtlsOptionsId: Int64
    public let name: String
    public let description: String
    public private(set) var timestamp: Date
    public private(set) var userPosition: CGPoint
    public var eventType: EventType
    public private(set) var tags: [String: String]
    public private(set) var metaData: [String: String]
    public private(set) var hasBeenTriggered: Bool
    
    public init(
        rtlsOptionsId: Int64,
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
        public static let id: String = "@message.id"
        public static let pollId: String = "@message.content.poll.id"
        public static let name: String = "@message.name"
        public static let messageShown: String = "messageShown"
        public static let pollResponse: String = "@message.content.poll.option"
    }

    public struct DefaultMetaData {
        public static let title: String = "@message.content.title"
        public static let body: String = "@message.content.body"
        public static let imageUrl: String = "@message.content.imageUrl"
        public static let type: String = "@message.type"
        public static let size: String = "@message.content.card.size"
        public static let poll: String = "@message.content.poll"

        public enum MessageType: String {
            case poll = "POLL"
            case popUp = "POP_UP"
        }

        public enum MessageSize: String {
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

    public func convertMetaDataToDefaultMessage() -> Message? {
        guard
            let title = metaData[DefaultMetaData.title],
            let type = metaData[DefaultMetaData.type]
        else { return nil }

        var poll: Message.Poll?
        if
            let data = metaData[DefaultMetaData.poll]?.data(using: .utf8),
            let parsedPoll = try? JSONSerialization.jsonObject(with: data) as? [String : Any],
            let question = parsedPoll["question"] as? String,
            let type = parsedPoll["type"] as? String,
            let parsedOptions = parsedPoll["options"] as? NSArray
        {
            var options: [Message.Poll.Option] = []
            parsedOptions.forEach {
                guard
                    let dict = $0 as? NSDictionary,
                    let description = dict["description"] as? String,
                    let positionInList = dict["positionInList"] as? Int
                else { return }
                options.append(Message.Poll.Option(description: description, imageUrl: dict["imageUrl"] as? String, positionInList: positionInList))
            }
            poll = Message.Poll(question: question, type: .init(rawValue: type) ?? .radio, options: options)
        }

        return Message(
          title: title,
          body: metaData[DefaultMetaData.body],
          imageUrl: metaData[DefaultMetaData.imageUrl],
          poll: poll,
          type: .init(rawValue: type) ?? (poll == nil ? .popUp : .poll),
          size: .init(rawValue: metaData[DefaultMetaData.size] ?? "")
        )
    }

    public enum TriggerType: String {
        case enter = "ENTER"
        case exit = "EXIT"
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
        public let type: TriggerType
        
        public init(point: CGPoint, radius: Double, type: TriggerType) {
            self.point = point
            self.radius = radius
            self.type = type
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
        public let type: TriggerType

        public init(zoneId: String, groupId: String, type: TriggerType) {
            self.zoneId = zoneId
            self.groupId = groupId
            self.type = type
        }
        
        var asPostTrigger: PostTriggerEventRequest.ZoneTrigger {
            PostTriggerEventRequest.ZoneTrigger(zoneId: zoneId, groupId: groupId, type: PostTriggerEventRequest.ZoneTrigger.ZoneType.init(rawValue: type.rawValue) ?? .enter)
        }
    }

    public struct Message {
        public let title: String
        public let body: String?
        public let imageUrl: String?
        public let poll: Poll?
        public let type: DefaultMetaData.MessageType
        public let size: DefaultMetaData.MessageSize?

        public struct Poll {
            public let question: String
            public let type: PollType
            public let options: [Option]

            public enum PollType: String {
                case checkbox = "checkbox"
                case number = "number"
                case radio = "radio"
                case text = "text"
            }

            public struct Option {
                public let description: String
                public let imageUrl: String?
                public let positionInList: Int
            }
        }
    }
}

public extension TriggerEvent {
    var toMessageShown: TriggerEvent? {
        guard let id = self.tags[DefaultTags.id] else { return nil }
        var tags: [String : String] = [:]
        self.tags.forEach { (key, value) in
            tags[key] = value
        }
        tags[DefaultTags.messageShown] = id
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

    func toPollResponse(option: Message.Poll.Option) -> TriggerEvent? {
        var tags: [String : String] = [:]
        self.tags.forEach { (key, value) in
            tags[key] = value
        }
        tags[DefaultTags.pollResponse] = option.description
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
