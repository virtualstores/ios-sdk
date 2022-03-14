//
// Analytics
// VSTT2
//
// Created by Hripsime on 2022-01-13
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import CoreGraphics
import Combine

public protocol TT2Analytics {
    /// Start  Analytics with device data
    func startVisit(deviceInformation: DeviceInformation, tags: [String: String], metaData: [String: String], completion: @escaping (Error?) -> Void)

    /// Setup analytics Manager with needed data
    func setup(with store: Store, rtlsOptionId: Int64?, uploadThreshold: Int, config: EnvironmentConfig?)

    /// Start  Collecting Heat Map
    func startCollectingHeatMapData() throws

    /// Stop  Collecting Heat Map
    func stopCollectingHeatMapData()

    /// Stop  Analytics
    func stopVisit()
    
    /// Method for adding event from app
    func addTriggerEvent(for event: TriggerEvent)
}

enum TT2AnalyticsError: Error {
    case visitNotStarted
}
