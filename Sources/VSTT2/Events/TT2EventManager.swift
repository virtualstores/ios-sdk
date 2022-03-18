//
// TT2EventManager
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine
import CoreGraphics

public class TT2EventManager: TT2Event {
    @Inject var messagesService: MessagesService
    @Inject var zoneEventDetector: ZoneEventDetector
    @Inject var coordinateEventDetector: CoordinateEventDetector
    
    public var messageEventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
    public var pointOfInterestPublisher: CurrentValueSubject<PointOfInterest?, Never> = .init(nil)
    
    private var activeStoreId: Int64?
    private var rtlsOptionsId: Int64 = 0

    private var messages: [Message] = []
    private var latestMessageLoad: Date?
    private let reloadMessageInterval: TimeInterval = 3600.0
    private var zones: [Zone] = []
    
    private var cancellable = Set<AnyCancellable>()
    private var zoneEnterCancellable: AnyCancellable?
    private var coordinateEnterCancellable: AnyCancellable?
    private var config: EnvironmentConfig?
    
    internal func setup(with storeId: Int64, zones: [Zone], rtlsOptionsId: Int64, config: EnvironmentConfig?) {
        self.activeStoreId = storeId
        self.zones = zones
        self.rtlsOptionsId = rtlsOptionsId
        self.config = config
        
        zoneEventDetector.setup(with: zones)
        loadMessagesIfNeeded()
        bindPubloshers()
    }
    
    public func addEvent(event: TriggerEvent) {
        switch event.eventType {
        case .zoneTrigger(_): zoneEventDetector.add(event: event)
        case .coordinateTrigger(_): coordinateEventDetector.add(event: event)
        default: break
        }
    }

    public func removeEvent(with id: String) { }

    public func onNewPosition(currentPosition: CGPoint) {
        zoneEventDetector.onNewPosition(currentPosition: currentPosition)
        coordinateEventDetector.onNewPosition(currentPosition: currentPosition)
    }
    
    public func bindPubloshers() {
        self.zoneEnterCancellable = zoneEventDetector.eventPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneEnteredPublisher error")
            } receiveValue: { [weak self] event in
                self?.messageEventPublisher.send(event)
            }
        
        self.coordinateEnterCancellable = coordinateEventDetector.eventPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneEnteredPublisher error")
            } receiveValue: { [weak self] event in
                self?.messageEventPublisher.send(event)
            }
    }
    
    private func loadMessagesIfNeeded() {
        if let latestMessageLoad = latestMessageLoad {
            if latestMessageLoad.timeIntervalSinceNow < -reloadMessageInterval {
                loadMessages()
            }
        } else {
            loadMessages()
        }
    }

    private func loadMessages() {
        guard let storeId = activeStoreId else { return }

        let parameters = MessagesParameters(storeId: storeId, config: config)
        messagesService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                       message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] (messageDto) in
                self?.messages = messageDto.compactMap { $0.toMessage() }
                
                guard let messages = self?.messages else { return }
                
                for (_, message) in messages.enumerated() {
                    switch message.exposureType {
                    case .zones:
                        self?.createZoneEvents(for: message)
                    case .products:
                        self?.createCoordinatEvents(for: message)
                    default: break
                    }
                }
                self?.latestMessageLoad = .init()
            }).store(in: &cancellable)
    }
    
    private func createZoneEvents(for message: Message) {
        let trigger = TriggerEvent.EventType.zoneTrigger(TriggerEvent.ZoneTrigger(zoneId: message.zones.first!.name, groupId: "", type: .enter))
        let metaData = addMetaData(for: message)
        let event = TriggerEvent(rtlsOptionsId: String(rtlsOptionsId), name: message.name, description: message.description, eventType: trigger, metaData: metaData)
        self.zoneEventDetector.add(event: event)
    }
    
    private func createCoordinatEvents(for message: Message) {
        let coordinateTrigger = TriggerEvent.EventType.coordinateTrigger(TriggerEvent.CoordinateTrigger(point: .zero, radius: message.radius))
        let metaData = addMetaData(for: message)
        let event = TriggerEvent(rtlsOptionsId: String(rtlsOptionsId), name: message.name, description: message.description, eventType: coordinateTrigger, metaData: metaData)
        self.coordinateEventDetector.add(event: event)
    }

    private func addMetaData(for message: Message) -> [String : String] {
        let type: TriggerEvent.DefaultMetaData.MessageType = message.cardType == .big ? .large : .small
        let defaultMetaData = TriggerEvent.DefaultMetaData()
        let metaData = [
            defaultMetaData.id : String(message.id),
            defaultMetaData.title : message.title,
            defaultMetaData.body : message.description,
            defaultMetaData.imageUrl : message.image?.description ?? "",
            defaultMetaData.type : type.rawValue
        ]
        return metaData
    }
}
