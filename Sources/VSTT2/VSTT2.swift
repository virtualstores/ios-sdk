//
// VSTT2
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import Combine

/// Manager for VSTT2 data. Will give all data which need iOS app
public protocol VSTT2 {
    /// Starts VSTT2 managers. Will produce results to publisher.
    func start() throws

    /// Stops VSTT2 managers..
    func stop()

    /// Temporary setter for activating and deactivating background access in positionKit
    func setBackgroundAccess(isActive: Bool)

    /// Temporary publisher for step counts test
    var stepCountPublisher: CurrentValueSubject<Int, Never> { get }
}
