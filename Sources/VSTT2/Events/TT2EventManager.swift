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
    @Inject var zoneEventDetectore: ZoneEventDetector
    @Inject var coordinateEventDetectore: CoordinateEventDetector
    
    public var messageEventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
    public var pointOfInterestPublisher: CurrentValueSubject<PointOfInterest?, Never> = .init(nil)
    
    private var activeStoreId: Int64?
    private var messages: [Message] = []
    private var latestMessageLoad: Date?
    private let reloadMessageInterval: TimeInterval = 3600.0
    private var zones: [Zone] = []
    
    private var cancellable = Set<AnyCancellable>()
    private var zoneEnterCancellable: AnyCancellable?
    
    internal func setup(with storeId: Int64, zones: [Zone]) {
        self.activeStoreId = storeId
        self.zones = zones
        
        zoneEventDetectore.setup(with: zones)
        loadMessagesIfNeeded()
        bindPubloshers()
    }
    
    public func addEvent(with id: String, event: TriggerEvent) {}

    public func removeEvent(with id: String) { }
    
    public func onNewPosition(currentPosition: CGPoint) {
        zoneEventDetectore.onNewPosition(currentPosition: currentPosition)
        coordinateEventDetectore.onNewPosition(currentPosition: currentPosition)
    }
    
    public func bindPubloshers() {
        self.zoneEnterCancellable = zoneEventDetectore.zooneEventPublisher
            .compactMap { $0 }
            .sink { _ in
                Logger.init().log(message: "zoneEnteredPublisher error")
            } receiveValue: { [weak self] event in
                
                self?.messageEventPublisher.send( event)
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

        let parameters = MessagesParameters(storeId: storeId)
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
        let zoneIds = message.zones.map({ String($0.name) })

        let appTrigger = TriggerEvent.EventType.appTrigger(TriggerEvent.AppTrigger(event: message.name, zoneIds: zoneIds))
        let type = message.cardType == .big ? "BIG" : "SMALL"
        
        let event = TriggerEvent(rtlsOptionsId: "", name: message.name, timestamp: Date(), userPosition: .zero, eventType: appTrigger, tags:  ["messageShown": String(message.id)], metaData: ["Title": message.title, "Body": message.description, "Size": type])
        
        self.zoneEventDetectore.add(event: event)
    }
    
    private func createCoordinatEvents(for message: Message) {
        let coordinateTrigger = TriggerEvent.EventType.coordinateTrigger(TriggerEvent.CoordinateTrigger(point: .zero, radius: message.radius))
        
        let event = TriggerEvent(rtlsOptionsId: "", name: message.name, timestamp: Date(), userPosition: .zero, eventType: coordinateTrigger, tags: [:], metaData: [:])
        self.coordinateEventDetectore.add(event: event)
    }
}
