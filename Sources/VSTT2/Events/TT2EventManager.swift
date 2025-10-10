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
  @Inject var activeStore: GetActiveStoreUseCase
  @Inject var activeFloor: GetActiveFloorUseCase
  @Inject var getZonesTree: GetZonesTreeUseCase
  @Inject var messagesService: MessagesService
  @Inject var triggerEventsService: TriggerEventsService
  @Inject var eventDetector: EventDetector

  public var messageEventPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
  public var pointOfInterestPublisher: CurrentValueSubject<PointOfInterest?, Never> = .init(nil)

  var messageShownPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)

  private var activeStoreId: Int64 { (try? activeStore.invoke().id) ?? -1 }
  private var rtlsOptionsId: Int64 { (try? activeFloor.invoke().id) ?? -1 }

  public var triggerEvents: [TriggerEvent] = []
  private var latestMessageLoad: Date?
  private let reloadMessageInterval: TimeInterval = 3600.0
  private var zones: [Zone] { (try? getZonesTree.invoke())?.getZonesFor(floorLevelId: rtlsOptionsId) ?? [] }
  private var view: UIView?
  private var inAndOut: InAndOut?

  private var cancellable = Set<AnyCancellable>()

  init() {
    bindPublishers()
  }

  deinit {
    cancellable.removeAll()
  }

  func setup() {
    eventDetector.setup(with: zones)
    latestMessageLoad = nil
    loadMessagesIfNeeded()
  }

  func on(new position: VPSOutputSignal.Position) {
    eventDetector.on(new: position)
  }
}

private extension TT2EventManager {
  func bindPublishers() {
    eventDetector.eventPublisher
      .compactMap { $0 }
      .sink { [weak self] (event) in
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
      guard !event.hasBeenTriggered else { return }
      let message = MessageViews.shared//(type: converted.size)
      message.load(type: converted.size, imageUrl: converted.imageUrl, view: view) { (error) in
        if error == nil {
          event.updateEventStatus(hasBeenTriggered: true)
        }
      }
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
    triggerEventsService
      .call(with: TriggerEventsParameters(storeId: activeStoreId))
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): Logger(verbosity: .debug).log(tag: Logger.createTag(fileName: #file, functionName: #function), message: error.localizedDescription)
        }
      } receiveValue: { [weak self] (events) in
        self?.triggerEvents = events.map { $0.toTriggerEvent(mapZones: self?.zones ?? []) }.flatMap { $0 }
        self?.eventDetector.set(events: self?.triggerEvents ?? [])
        self?.latestMessageLoad = .init()
      }.store(in: &cancellable)
  }
}

extension TT2EventManager: TT2Event {
  public func add(event: TriggerEvent) {
    eventDetector.add(event: event)
  }

  public func remove(event: TriggerEvent) {
    eventDetector.remove(event: event)
  }

  public func remove(event id: String) {
    if let event = eventDetector.events.first(where: { $0.name == id }) {
      remove(event: event)
    }
  }

  public func enableAutoShow(view: UIView?) {
    self.view = view
  }
}
