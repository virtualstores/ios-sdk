//
// Analytics
// VSTT2
//
// Created by Hripsime on 2022-01-13
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import CoreLocation
import Combine

public protocol TT2Analytics {
    var hasVisit: Bool { get }
    /// Start  Analytics with device data
    func startVisit(deviceInformation: DeviceInformation, tags: [String: String], metaData: [String: String], completion: @escaping (Result<Int64, Error>) -> Void)

    /// Start  Collecting Heat Map
    func startCollectingHeatMapData() throws

    /// Stop  Collecting Heat Map
    func stopCollectingHeatMapData()

    /// Stop  Analytics
    func stopVisit()
    
    /// Method for adding event from app
    func addTriggerEvent(for event: TriggerEvent)

    func addGeopositions(coordinate: CLLocationCoordinate2D, for tag: String)

    func startTrackingWayfinding(itemPosition: ItemPosition)

    func stopTrackingWayfinding(itemPosition: ItemPosition)
  
    func startTrackingWayfinding(zonePosition: ZonePosition)

    func stopTrackingWayfinding(zonePosition: ZonePosition)
}

public extension TT2Analytics {
  func startVisit(deviceInformation: DeviceInformation, tags: [String: String] = [:], metaData: [String: String] = [:], completion: @escaping (Result<Int64, Error>) -> Void) {
    startVisit(deviceInformation: deviceInformation, tags: tags, metaData: metaData, completion: completion)
  }
}

enum TT2AnalyticsError: Error {
    case visitAlreadyStarted
    case visitNotStarted
}
