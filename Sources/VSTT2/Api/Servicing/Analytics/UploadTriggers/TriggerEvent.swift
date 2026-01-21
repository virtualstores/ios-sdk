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
    public let eventType: EventType
    public private(set) var tags: [String: String]
    public private(set) var metaData: [String: String]
    public private(set) var hasBeenTriggered: Bool

    public var messageId: String? { tags[.id] }

    var id = UUID().uuidString
    var timestamp: Date
    var userPosition: CGPoint?

    init(
        rtlsOptionsId: Int64,
        name: String,
        description: String,
        eventType: EventType,
        tags: [String: String] = [:],
        metaData: [String: String] = [:],
        hasBeenTriggered: Bool = false,
        timestamp: Date = Date(),
        userPosition: CGPoint? = nil
    ) {
        self.rtlsOptionsId = rtlsOptionsId
        self.name = name
        self.description = description
        self.eventType = eventType
        self.tags = tags
        self.metaData = metaData
        self.hasBeenTriggered = false
        self.timestamp = timestamp
        self.userPosition = userPosition
    }
  
    public convenience init(
        id: String,
        rtlsOptionsId: Int64,
        name: String,
        description: String,
        eventType: EventType,
        tags: [String: String] = [:],
        metaData: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.init(rtlsOptionsId: rtlsOptionsId, name: name, description: description, eventType: eventType, tags: tags, metaData: metaData, timestamp: timestamp)
        self.tags[.id] = id
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

    public enum DefaultTags {
        public static let id: String = "@message.id"
        public static let pollId: String = "@message.content.poll.id"
        public static let name: String = "@message.name"
        public static let messageShown: String = "messageShown"
        public static let pollResponse: String = "@message.content.poll.option"
        public static let displayType: String = "@message.display.type"
        public static let shareOfVoice: String = "@message.shareOfVoice"

        public enum DisplayTypeEnum: String {
          case image = "IMAGE"
        }
    }

    public enum DefaultMetaData {
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
            case big = "BIG"
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
        guard let type = metaData[DefaultMetaData.type] else { return nil }

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
          title: metaData[DefaultMetaData.title],
          body: metaData[DefaultMetaData.body],
          imageUrl: metaData[DefaultMetaData.imageUrl],
          poll: poll,
          type: .init(rawValue: type) ?? (poll == nil ? .popUp : .poll),
          size: .init(rawValue: metaData[DefaultMetaData.size] ?? "")
        )
    }

    func shareOfVoice() -> Double {
        tags[DefaultTags.shareOfVoice]?.asDouble ?? 1.0
    }

    public func convertEventToImageMessage() -> (imageUrl: String, size: DefaultMetaData.MessageSize, type: DefaultTags.DisplayTypeEnum?)? {
      guard
        let imageUrl = metaData[DefaultMetaData.imageUrl],
        let size = DefaultMetaData.MessageSize(rawValue: metaData[DefaultMetaData.size] ?? "")
      else { return nil }
      return (imageUrl, size, DefaultTags.DisplayTypeEnum(rawValue: tags[DefaultTags.displayType] ?? ""))
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
        public let entryPoint: EntryPoint?

        public init(zoneId: String, groupId: String, type: TriggerType, entryPoint: EntryPoint?) {
            self.zoneId = zoneId
            self.groupId = groupId
            self.type = type
            self.entryPoint = entryPoint
        }
        
        var asPostTrigger: PostTriggerEventRequest.ZoneTrigger {
            PostTriggerEventRequest.ZoneTrigger(zoneId: zoneId, groupId: groupId, type: PostTriggerEventRequest.ZoneTrigger.ZoneType.init(rawValue: type.rawValue) ?? .enter)
        }

        public struct EntryPoint {
            let line: [CGPoint]
            let id: String

            public init(line: [CGPoint], id: String) {
                self.line = line
                self.id = id
            }
        }
    }

    public struct Message {
        public let title: String?
        public let body: String?
        public let imageUrl: String?
        public let poll: Poll?
        public let type: DefaultMetaData.MessageType
        public let size: DefaultMetaData.MessageSize?

        public init(title: String?, body: String?, imageUrl: String?, poll: Poll?, type: DefaultMetaData.MessageType, size: DefaultMetaData.MessageSize?) {
            self.title = title
            self.body = body
            self.imageUrl = imageUrl
            self.poll = poll
            self.type = type
            self.size = size
        }

        public struct Poll {
            public let question: String
            public let type: PollType
            public let options: [Option]

            public init(question: String, type: PollType, options: [Option]) {
                self.question = question
                self.type = type
                self.options = options
            }

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

                public init(description: String, imageUrl: String?, positionInList: Int) {
                    self.description = description
                    self.imageUrl = imageUrl
                    self.positionInList = positionInList
                }
            }
        }
    }
}

extension TriggerEvent {
  func asRequest(userPosition: CGPoint) -> PostTriggerEventRequest {
    .init(
      rtlsOptionsId: rtlsOptionsId.description,
      name: name,
      timestamp: .dateWithStandardFormatter(timestamp),
      userPosition: self.userPosition ?? userPosition,
      appTrigger: eventType.getTrigger().appTrigger?.asPostTrigger,
      coordinateTrigger: eventType.getTrigger().coordinateTrigger?.asPostTrigger,
      shelfTrigger: eventType.getTrigger().shelfTrigger?.asPostTrigger,
      zoneTrigger: eventType.getTrigger().zoneTrigger?.asPostTrigger,
      tags: tags,
      metaData: metaData
    )
  }

  func checkForZoneTrigger() -> TriggerEvent {
    guard
      let trigger = eventType.getTrigger().zoneTrigger,
      let pointId = trigger.entryPoint?.id
    else { return self }
    switch trigger.type {
    case .enter: add(tags: ["entryPointEnterId": pointId])
    case .exit: add(tags: ["entryPointExitId": pointId])
    }
    return self
  }
}

public extension TriggerEvent {
    var toMessageShown: TriggerEvent? {
        guard let id = tags[.id] else { return nil }
        var tags: [String:String] = tags
        tags[.messageShown] = id
        return TriggerEvent(
            rtlsOptionsId: rtlsOptionsId,
            name: name,
            description: description,
            eventType: .appTrigger(TriggerEvent.AppTrigger(event: name)),
            tags: tags,
            metaData: metaData,
            hasBeenTriggered: hasBeenTriggered,
            timestamp: timestamp,
            userPosition: userPosition
        )
    }

    func toPollResponse(option: Message.Poll.Option) -> TriggerEvent {
        var tags: [String:String] = tags
        tags[.pollResponse] = option.description
        return TriggerEvent(
            rtlsOptionsId: rtlsOptionsId,
            name: name,
            description: description,
            eventType: .appTrigger(TriggerEvent.AppTrigger(event: name)),
            tags: tags,
            metaData: metaData,
            hasBeenTriggered: hasBeenTriggered,
            timestamp: timestamp,
            userPosition: userPosition
        )
    }
}

public struct ScanEvent {
  public let barcode: String
  public let point: CGPoint?
  public let timestamp: String
  public let type: ShelfType
  public let userPosition: CGPoint?
  public let floorLevelId: Int64? // For old version of scan event
  public let shelfId: Int64? // For old version of scan event
  public let shelfTierId: Int64? // For old version of scan event
  public let shelfTierPosition: Int64? // For old version of scan event
  public let shelfSectionId: String? // For new version of scan event
  public let sectionPosition: Int? // For new version of scan event
  public let shelfPositionFromLeftToRight: Int? // For new version of scan event
  public let zoneIds: [String]?

  public enum ShelfType: Int {
    case unknown = 0
    case shelf = 1
    case shelfSection = 2
    case zone = 3
  }

  init(barcode: String, point: CGPoint?, timestamp: String, type: ShelfType, userPosition: CGPoint? = nil, floorLevelId: Int64? = nil, shelfId: Int64? = nil, shelfTierId: Int64? = nil, shelfTierPosition: Int64? = nil, shelfSectionId: String? = nil, sectionPosition: Int? = nil, shelfPositionFromLeftToRight: Int? = nil, zoneIds: [String]? = nil) {
    self.barcode = barcode
    self.point = point
    self.timestamp = timestamp
    self.type = type
    self.userPosition = userPosition
    self.floorLevelId = floorLevelId
    self.shelfId = shelfId
    self.shelfTierId = shelfTierId
    self.shelfTierPosition = shelfTierPosition
    self.shelfSectionId = shelfSectionId
    self.sectionPosition = sectionPosition
    self.shelfPositionFromLeftToRight = shelfPositionFromLeftToRight
    self.zoneIds = zoneIds
  }

  public static func createShelfScanEvent(itemPosition: ItemPosition, userPosition: CGPoint?) -> ScanEvent {
    ScanEvent(
      barcode: itemPosition.identifier,
      point: itemPosition.point,
      timestamp: DateFormatter.standardFormatter.string(from: Date()),
      type: .shelf,
      userPosition: userPosition,
      floorLevelId: itemPosition.floorLevelId,
      shelfId: itemPosition.shelfId,
      shelfTierId: itemPosition.shelfTierId,
      shelfTierPosition: itemPosition.shelfTierPosition
    )
  }

  private static func createShelfSectionScanEvent(itemPosition: ItemPosition, userPosition: CGPoint?) -> ScanEvent {
    ScanEvent(
      barcode: itemPosition.identifier,
      point: itemPosition.point,
      timestamp: DateFormatter.standardFormatter.string(from: Date()),
      type: .shelfSection,
      userPosition: userPosition,
      floorLevelId: itemPosition.floorLevelId,
      shelfSectionId: itemPosition.shelfSectionId,
      sectionPosition: itemPosition.sectionPosition,
      shelfPositionFromLeftToRight: itemPosition.shelfPositionFromLeftToRight
    )
  }

  public static func createZoneScanEvent(identifier: String, floorLevelId: Int64, userPosition: CGPoint?, zones: [String]) -> ScanEvent {
    ScanEvent(
      barcode: identifier,
      point: nil,
      timestamp: DateFormatter.standardFormatter.string(from: Date()),
      type: .zone,
      userPosition: userPosition,
      floorLevelId: floorLevelId,
      shelfSectionId: nil,
      sectionPosition: nil,
      shelfPositionFromLeftToRight: nil,
      zoneIds: zones
    )
  }

  public static func createUnknownScanEvent(identfier: String, floorLevelId: Int64, userPosition: CGPoint?) -> ScanEvent {
    ScanEvent(
      barcode: identfier,
      point: nil,
      timestamp: DateFormatter.standardFormatter.string(from: Date()),
      type: .unknown,
      userPosition: userPosition,
      floorLevelId: floorLevelId
    )
  }
}

private extension String {
  static let id: String = TriggerEvent.DefaultTags.id
  static let messageShown: String = TriggerEvent.DefaultTags.messageShown
  static let pollResponse: String = TriggerEvent.DefaultTags.pollResponse
  var asDouble: Double? { Double(self) }
}
