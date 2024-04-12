//
// TT2EventManager
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine
import UIKit

public class TT2EventManager {
  @Inject var floorManager: VSTT2FloorManager
  @Inject var messagesService: MessagesService
  @Inject var triggerEventsService: TriggerEventsService
  @Inject var zoneEventDetector: ZoneEventDetector
  @Inject var coordinateEventDetector: CoordinateEventDetector

  public var messageEventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
  public var pointOfInterestPublisher: CurrentValueSubject<PointOfInterest?, Never> = .init(nil)

  var messageShownPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)

  private var activeStoreId: Int64?
  private var rtlsOptionsId: Int64 = 0

  public var triggerEvents: [TriggerEvent] = []
  private var latestMessageLoad: Date?
  private let reloadMessageInterval: TimeInterval = 3600.0
  private var zones: [Zone] = []
  private var view: UIView?

  private var cancellable = Set<AnyCancellable>()

  deinit {
    cancellable.removeAll()
  }

  func setup(with storeId: Int64, zones: [Zone], rtlsOptionsId: Int64) {
    self.activeStoreId = storeId
    self.zones = zones
    self.rtlsOptionsId = rtlsOptionsId

    zoneEventDetector.setup(with: zones)
    latestMessageLoad = nil
    loadMessagesIfNeeded()
    bindPublishers()
  }

  func onNewPosition(currentPosition: CGPoint) {
    zoneEventDetector.onNewPosition(currentPosition: currentPosition)
    coordinateEventDetector.onNewPosition(currentPosition: currentPosition)
  }
}

private extension TT2EventManager {
  func bindPublishers() {
    zoneEventDetector.eventPublisher
      .compactMap { $0 }
      .sink { (_) in
        Logger().log(message: "zoneEnteredPublisher error")
      } receiveValue: { [weak self] (event) in
        DispatchQueue.main.async {
          self?.handle(event: event)
        }
      }
      .store(in: &cancellable)

    coordinateEventDetector.eventPublisher
      .compactMap { $0 }
      .sink { (_) in
        Logger().log(message: "zoneEnteredPublisher error")
      } receiveValue: { [weak self] (event) in
        DispatchQueue.main.async {
          self?.handle(event: event)
        }
      }
      .store(in: &cancellable)
  }

  func handle(event: TriggerEvent) {
    guard 
      let view = view,
      let converted = event.convertEventToImageMessage()
    else { messageEventPublisher.send(event); return }
    switch converted.type {
    case .image:
      let message = MessageViews(type: converted.size)
      message.load(imageUrl: converted.imageUrl, view: view)
      message.onClose = { [weak self] in
        self?.messageShownPublisher.send(event.toMessageShown)
      }
    default: messageEventPublisher.send(event)
    }
  }

  func loadMessagesIfNeeded() {
    if let latestMessageLoad = latestMessageLoad {
      guard latestMessageLoad.timeIntervalSinceNow < -reloadMessageInterval else { return }
      loadMessages()
    } else {
      loadMessages()
    }
  }

  func loadMessages() {
    guard let storeId = activeStoreId else { return }

    let parameters = TriggerEventsParameters(storeId: storeId)
    triggerEventsService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): Logger(verbosity: .debug).log(tag: Logger.createTag(fileName: #file, functionName: #function), message: error.localizedDescription)
        }
      } receiveValue: { [weak self] (events) in
        self?.triggerEvents = events.map { $0.toTriggerEvent(mapZones: self?.zones ?? []) }.flatMap { $0 }
        self?.triggerEvents.forEach { event in
          let type = event.eventType.getTrigger()
          if type.coordinateTrigger != nil {
            self?.coordinateEventDetector.add(event: event)
          } else if type.zoneTrigger != nil {
            self?.zoneEventDetector.add(event: event)
          }
        }
        self?.latestMessageLoad = .init()
      }.store(in: &cancellable)
  }
}

extension TT2EventManager: TT2Event {
  public func add(event: TriggerEvent) {
    switch event.eventType {
    case .coordinateTrigger(_): coordinateEventDetector.add(event: event)
    case .zoneTrigger(_): zoneEventDetector.add(event: event)
    case .appTrigger(_), .shelfTrigger(_): break
    }
  }

  public func remove(event: TriggerEvent) {
    switch event.eventType {
    case .coordinateTrigger(_): coordinateEventDetector.remove(event: event)
    case .zoneTrigger(_): zoneEventDetector.remove(event: event)
    case .appTrigger(_), .shelfTrigger(_): break
    }
  }

  public func remove(event id: String) {
    if let event = coordinateEventDetector.events.first(where: { $0.name == id }) {
      remove(event: event)
    }
    if let event = zoneEventDetector.events.first(where: { $0.name == id }) {
      remove(event: event)
    }
  }

  public func enableAutoShow(view: UIView?) {
    self.view = view
  }
}
