//
// Analytics
// VSTT2
//
// Created by Hripsime on 2022-01-13
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import CoreGraphics

public protocol TT2Analytics {
    /// Start  Analytics with device data
    func startVisit(deviceInformation: DeviceInformation, tags: [String: String], metaData: [String: String])

    ///Setup analytics Manager with needed data
    func setup(with store: Store, uploadThreshold: Int)
    
    /// Start  Collecting Heat Map
    func startCollectingHeatMapData() throws
    
    /// Stop  Collecting Heat Map
    func stopCollectingHeatMapData()

    /// Stop  Analytics
    func stopVisit()
    
    /// Updates  position data each time
    func onNewPositionBundle(point: CGPoint)
}

enum TT2AnalyticsError: Error {
    case visitNotStarted
}
