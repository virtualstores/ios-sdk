//
// INavigation
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Combine
import CoreGraphics
import CoreLocation
import Foundation
import VSFoundation

public protocol INavigation: Disposable {
    var positionPublisher: AnyPublisher<VPSOutputSignal.Position?, Never> { get }

    /// Flag for checking if sdk is active
    var isActive: Bool { get }
    var compassHeading: Double? { get }
    var currentPosition: CGPoint? { get }

    func syncPosition(identifier: String, syncAngle: Bool, uncertainAngle: Bool, withForce: Bool, reportScanEvent: Bool, returnOn queue: DispatchQueue, completion: @escaping (Result<Item,Error>) -> ())

    func syncPosition(location: CLLocation) throws

    /// This will stop notifying the location publishers.
    func stop()
    
    /// Provide device start angle
    func prepareAngle()
}

public extension INavigation {
  func syncPosition(
    identifier: String,
    syncAngle: Bool = false,
    uncertainAngle: Bool = true,
    withForce: Bool = false,
    reportScanEvent: Bool = true,
    returnOn queue: DispatchQueue = .main,
    completion: @escaping (Result<Item,Error>) -> () = { (_) in }
  ) {
    syncPosition(identifier: identifier, syncAngle: syncAngle, uncertainAngle: uncertainAngle, withForce: withForce, reportScanEvent: reportScanEvent, returnOn: queue, completion: completion)
  }
}

public enum SyncTypeEnum {
    case compass(forceSync: Bool = false)
    case normal(syncRotation: Bool)

    internal func get() -> (compass: (Bool)?, normal: (Bool)?) {
        switch self {
        case .compass(let forceSync): return (compass: (forceSync), normal: nil)
        case .normal(let syncRotation): return (compass: nil, normal: (syncRotation))
        }
    }
}
