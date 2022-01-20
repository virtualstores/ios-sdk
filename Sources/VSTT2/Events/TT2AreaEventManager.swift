//
// TT2AreaEventManager
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine

public class TT2AreaEventManager: TT2AreaEvent {
    @Inject var messagesService: MessagesService
    
    public var areaEventPublisher: CurrentValueSubject<AreaEvent?, TT2AreaEventError> = .init(nil)

    private var activeStore: Store?
    private var messages: [Message]?
    private var latestMessageLoad: Date?
    private let reloadMessageInterval: TimeInterval = 3600.0

    private var cancellable = Set<AnyCancellable>()
    
    public func addEvent(with id: String, event: AreaTrigger) {
        
    }
    
    public func removeEvent(with id: String) {
        
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
        guard let storeId = activeStore?.id else { return }

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
                self?.latestMessageLoad = .init()
            }).store(in: &cancellable)
    }
}
