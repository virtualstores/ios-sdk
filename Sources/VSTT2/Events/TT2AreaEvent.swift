//
// TT2AreaEvent
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import Foundation
import Combine

/// AreaEvent finterface. Will give all data which need iOS app for AreaEvent
public protocol TT2AreaEvent {
    var areaEventPublisher: CurrentValueSubject<AreaEvent?, TT2AreaEventError> { get }
    
    func addEvent(with id: String, event: AreaTrigger)
    
    func removeEvent(with id: String)
}

public enum TT2AreaEventError: Error {
}

