//
// VSTT2Floor
// VSTT2
//
// Created by Hripsime on 2022-02-22
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine

public protocol VSTT2Floor {
    /// Active Floor data
    var activeFloor: RtlsOptions { get throws }

    /// All available floors which user can have
    var floors: [RtlsOptions] { get }

    /// Method for setup Active Floor with options
    func setActiveFloor(with rtlsOptions: RtlsOptions)

    /// Method for setup Active Floor with floorLevel
    func setActiveFloor(with floorLevel: Int)
}
