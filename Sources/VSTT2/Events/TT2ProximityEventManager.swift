//
// TT2ProximityEventManager
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import VSFoundation
import Combine

public class TT2ProximityEventManager: TT2ProximityEvent {
    public var proximityEventPublisher: CurrentValueSubject<PointOfInterest?, TTT2ProximityEventError> = .init(nil)
    private let scale: Double
    private var pointsOfInterest: Set<PointOfInterest>? = []
    private var lastLocation: TT2Location?
    private var triggers: [String: ProximityTrigger]?

    public init(scale: Double) {
        self.scale = scale
    }

    public func addEvent(with id: String, event: ProximityTrigger) {

    }

    public func removeEvent(with id: String) {

    }

    private func checkEvents() {
        guard let triggers = triggers, let pointsOfInterest = pointsOfInterest else { return }

        for poi in pointsOfInterest {
            for (_, event) in triggers {
                if event.isEnabled, event.isFilterPointOfInteres, distance(from: poi) < event.triggerDistance {
                    proximityEventPublisher.send(poi)
                }
            }
        }
    }

    private func distance(from poi: PointOfInterest) -> Double {
        guard let itemPosition = poi.position, let userLocation = lastLocation else {
            return .infinity
        }

        let userPosition = userLocation.position
        let mapPosition = CGPoint(x: itemPosition.xPosition / scale, y: itemPosition.yPosition / scale)

        return sqrt(pow(userPosition.xPosition - Double(mapPosition.x), 2.0) + pow(userPosition.yPosition - Double(mapPosition.y), 2.0))
    }
}
