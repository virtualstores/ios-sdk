//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-20.
//

import Foundation
import Combine

/// Manager for VSTT2 data. Will give all data which need iOS app
public protocol VSTT2 {
    /// Starts VSTT2 managers. Will produce results to publisher.
    func start()

    /// Stops VSTT2 managers.
    func stop()
}

public enum VSTT2Error: Error {
    case noData
}
