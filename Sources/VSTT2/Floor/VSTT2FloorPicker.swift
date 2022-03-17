//
//  VSTT2FloorPicker.swift
//  ios-sdk
//
//  Created by Théodore Roos on 2022-03-16.
//  Copyright © 2022 Virtual Stores. All rights reserved.
//

import Foundation
import CoreGraphics
import Combine
import VSFoundation

class FloorPicker {
    var rtlsOptionId: Int64
    let swapLocations: [SwapLocation]

    var switchFloorPublisher: CurrentValueSubject<(rtlsOptionsId: Int64, point: CGPoint)?, Never> = .init(nil)

    var currentPosition = CGPoint()
    var currentDirection: Double?
    var portalPoint: CGPoint?

    var insideTeleport = false
    var hasBeenInTeleport = false
    var changeingFloor: Bool = false
    var timeSinceInTeleport: Date?
    var maxTimeOutSideTeleport: Double = 15.0 // 15sec
    var changeFloorTo = 0
    var currentPortal: SwapLocation?

    var currentlyChangeingFloor: Bool {
        self.hasBeenInTeleport && self.changeingFloor
    }

    init(rtlsOptionId: Int64, swapLocations: [SwapLocation]) {
        self.rtlsOptionId = rtlsOptionId
        self.swapLocations = swapLocations
    }

    func onNewPosition(location: CGPoint) {
        currentPosition = location
        teleportUpdater()

        if changeFloorTo != 0 {
            if let nextPortal = findNextPortal(dir: changeFloorTo), (hasBeenInTeleport) {
                if let rtlsOptionsId = findNextPortalName(nextPortalId: nextPortal.swapLocationToId), let portalPoint = portalPoint {
                    switchFloorPublisher.send((rtlsOptionsId: rtlsOptionsId, point: portalPoint))
                    self.rtlsOptionId = rtlsOptionsId
                    self.changeFloorTo = 0
                }
            }
        }
    }

    private func findNextPortal(dir: Int) -> SwapLocation.Path? {
        guard let paths = currentPortal?.paths else {
            return nil
        }

        let tempDir = dir <= -1 ? 2 : 1
        var path: SwapLocation.Path?
        for item in paths {
            path = item.direction.rawValue == tempDir ? item : nil
        }
        return path
    }

    private func findNextPortalName(nextPortalId: Int64) -> Int64? {
        for portal in swapLocations {
            if portal.id == nextPortalId {
                portalPoint = portal.point.coordinate
                return portal.rtlsOptionsId
            }
            else { portalPoint = nil }
        }
        return nil
    }

    func onNewDirection(direction: Double) {
        currentDirection = direction
    }

    func teleportUpdater() {
        insideTeleport = insideTeleporter()
        if insideTeleport {
            hasBeenInTeleport = true
            timeSinceInTeleport = Date()
        } else if let date = timeSinceInTeleport, (hasBeenInTeleport && (Date().timeIntervalSince(date) > maxTimeOutSideTeleport)) {
            hasBeenInTeleport = false
            currentPortal = nil
        }
    }

    func insideTeleporter() -> Bool { // put most of this shit in to init so we dont have to run it every frame.
        for swapLocation in swapLocations.filter({ $0.rtlsOptionsId == rtlsOptionId }) {
            if isPointInside(point: currentPosition, coordinates: swapLocation.coordinates)/*, swapLocation.rtlsOptionsId == TT2.shared.navigationSpace?.id ?? -1*/ {
                currentPortal = swapLocation
                return true
            }
        }
        return false
    }

    func isPointInside(point: CGPoint, coordinates: [CGPoint]) -> Bool {
        var intersectCount = 0
        for coordinate in 0...coordinates.count - 2 {
            if (intersectsLine(linePoint1: coordinates[coordinate], linePoint2: coordinates[coordinate+1], pee: point)) { intersectCount += 1 }
        }
        if(intersectsLine(linePoint1: coordinates[0], linePoint2: coordinates.last ?? CGPoint(), pee: point) ) { intersectCount += 1 } // checks line from last point to first point
        return intersectCount % 2 == 1
    }

    func intersectsLine(linePoint1: CGPoint, linePoint2: CGPoint, pee: CGPoint) -> Bool {
        let horizontalPoint = CGPoint(x: CGFloat(Float.greatestFiniteMagnitude), y: pee.y)

        let o1 = self.orientation(p1: linePoint1, p2: linePoint2, p3: pee)
        let o2 = self.orientation(p1: linePoint1, p2: linePoint2, p3: horizontalPoint)
        let o3 = self.orientation(p1: pee, p2: horizontalPoint, p3: linePoint1)
        let o4 = self.orientation(p1: pee, p2: horizontalPoint, p3: linePoint2)

        var result = false
        if (o1 != o2 && o3 != o4) {
            result = true
        }
        return result
    }

    func orientation(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> Int {
        let result = ((p2.y - p1.y) * (p3.x - p2.x)) - ((p2.x - p1.x) * (p3.y - p2.y))
        if (result == 0.0) {
            return 0
        }
        if (result > 0) {
            return 1
        }
        return 2
    }

    func changeOfFloor(floor: Int) {
        //print("Change floor to: \(floor)")
        self.changeFloorTo = floor
    }

    func changeOfFloorIndicator(floor: Int) {
        //walking on new flooor
    }
    //
    //    override fun timeToChangeFloorReset() {
    //    }
}
