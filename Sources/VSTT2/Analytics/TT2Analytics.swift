//
// Analytics
// VSTT2
//
// Created by Hripsime on 2022-01-13
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public protocol TT2Analytics {
    /// Start  Analytics with device data
    func startVisit(deviceInformation: DeviceInformation, tags: [String: String], metaData: [String: String])

    /// Start  Collecting Heat Map
    func startCollectingHeatMapData() throws

    /// Stop  Collecting Heat Map
    func stopCollectingHeatMapData()

    /// Stop  Analytics
    func stopVisit()
}

enum TT2AnalyticsError: Error {
    case visitNotStarted
}
