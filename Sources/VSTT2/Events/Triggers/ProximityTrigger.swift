//
// ProximityTrigger
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import Foundation

public struct ProximityTrigger {
    /// Trigger id
    var id: String

    /// If this trigger is enabled or not. If a trigger is disabled, it will not recieve events,
    var isEnabled: Bool

    /// How close the user needs to be a point of interest to trigger it. Specified in meters.
    var triggerDistance: Double

    /// Applies a filter so that only points of interests that fulfill this function can be triggered.
    var isFilterPointOfInteres: Bool
}
