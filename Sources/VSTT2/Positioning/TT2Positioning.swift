//
// TT2Positioning
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Foundation
import VSPositionKit
import Combine
import VSFoundation
import CoreGraphics

public protocol TT2Positioning {
    var stepCountPublisher: CurrentValueSubject<Int, Never> { get }
    var positionBundlePublisher: CurrentValueSubject<PositionBundle?, PositionKitError> { get }
    
    /// Synchronize the position manager with a currently known position.
    func startUpdatingLocation(_ location: TT2Location) throws
    
    /// Synchronize the position manager with a positioned code.
    func startUpdatingLocation(with code: PositionedCode, offset: Double?, syncDirection: Bool)
    
    /// This will stop notifying the location publishers.
    func stopUpdatingLocation(saveRecording: Bool, uploadRecording: Bool)
}
