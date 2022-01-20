//
// TT2ProximityEvent
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2022

import Foundation

import Foundation
import Combine

/// Proximity Event finterface. Will give all data which need iOS app for AreaEvent
public protocol TT2ProximityEvent {
    var proximityEventPublisher: CurrentValueSubject<PointOfInterest?, TTT2ProximityEventError> { get }
    
    func addEvent(with id: String, event: ProximityTrigger)
    
    func removeEvent(with id: String)
}

public enum TTT2ProximityEventError: Error {}
