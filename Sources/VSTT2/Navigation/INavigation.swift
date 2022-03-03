//
// INavigation
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Foundation
import VSPositionKit
import Combine
import VSFoundation
import CoreGraphics

public protocol INavigation {
    /// Synchronize the position manager with a currently known position.
    func start(_ location: TT2Location) throws

    /// Synchronize the position manager with a positioned code.
    func start(with code: PositionedCode, offset: Double?, syncDirection: Bool)

    /// This will stop notifying the location publishers.
    func stop(saveRecording: Bool, uploadRecording: Bool)
}
