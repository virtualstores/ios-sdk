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
    @Inject var cachedSwapLocations: GetCachedSwapLocationsUseCase
    @Inject var activeFloor: GetActiveFloorUseCase

    var swapLocations: [SwapLocation] { cachedSwapLocations.invoke() }
    var filteredSwapLocations: [SwapLocation] { swapLocations.filter({ $0.rtlsOptionsId == (try? activeFloor.invoke())?.id })}

    var switchFloorPublisher: CurrentValueSubject<(rtlsOptionsId: Int64, point: CGPoint)?, Never> = .init(nil)

    var currentPosition = CGPoint()
    var currentDirection: Double?

    var hasBeenInTeleport = false
    var changeingFloor: Bool = false
    var timeSinceInTeleport: Date?
    var maxTimeOutsideTeleport: Double = 15.0 // 15sec
    var currentPortal: SwapLocation?

    var currentlyChangeingFloor: Bool { hasBeenInTeleport && changeingFloor }

    func onNewPosition(location: CGPoint) {
        currentPosition = location
        teleportUpdater()
    }

    private func findPortalCorrectDir(dir: Int) -> SwapLocation.Path? {
        let tempDir = dir == -1 ? 2 : 1
        for swapLocation in filteredSwapLocations {
            return swapLocation.paths.first(where: {
              $0.direction.rawValue == tempDir &&
              isPointInside(point: currentPosition, coordinates: swapLocation.coordinates)
            })
        }
        return nil
    }

    private func findNextPortal(dir: Int) -> SwapLocation.Path? {
        let tempDir = dir <= -1 ? 2 : 1
        return currentPortal?.paths.first(where: { $0.direction.rawValue == tempDir })
    }

    private func findNextPortalName(nextPortalId: Int64) -> (rtlsOptionsId: Int64, portalPoint: CGPoint)? {
        guard let portal = swapLocations.first(where: { $0.id == nextPortalId }) else { return nil }
        return (portal.rtlsOptionsId, portal.point.coordinate)
    }

    func onNewDirection(direction: Double) {
        currentDirection = direction
    }

    func teleportUpdater() {
        if insideTeleporter() {
            hasBeenInTeleport = true
            timeSinceInTeleport = Date()
        } else if let date = timeSinceInTeleport, (hasBeenInTeleport && (Date().timeIntervalSince(date) > maxTimeOutsideTeleport)) {
            hasBeenInTeleport = false
            currentPortal = nil
        }
    }

    func insideTeleporter() -> Bool { // put most of this shit in to init so we dont have to run it every frame.
        for swapLocation in filteredSwapLocations {
            guard isPointInside(point: currentPosition, coordinates: swapLocation.coordinates) else { continue }
            currentPortal = swapLocation
            return true
        }
        return false
    }

    func isPointInside(point: CGPoint, coordinates: [CGPoint]) -> Bool {
        var intersectCount = 0
        for coordinate in 0..<coordinates.count - 1 {
            guard
              intersectsLine(linePoint1: coordinates[coordinate], linePoint2: coordinates[coordinate+1], pee: point)
            else { continue }
            intersectCount += 1
        }
        if intersectsLine(linePoint1: coordinates[0], linePoint2: coordinates.last ?? CGPoint(), pee: point) {
          intersectCount += 1 // checks line from last point to first point
        }
        return intersectCount % 2 == 1
    }

    func intersectsLine(linePoint1: CGPoint, linePoint2: CGPoint, pee: CGPoint) -> Bool {
        let horizontalPoint = CGPoint(x: CGFloat(Float.greatestFiniteMagnitude), y: pee.y)

        let o1 = orientation(p1: linePoint1, p2: linePoint2, p3: pee)
        let o2 = orientation(p1: linePoint1, p2: linePoint2, p3: horizontalPoint)
        let o3 = orientation(p1: pee, p2: horizontalPoint, p3: linePoint1)
        let o4 = orientation(p1: pee, p2: horizontalPoint, p3: linePoint2)

        var result = false
        if o1 != o2 && o3 != o4 {
            result = true
        }
        return result
    }

    func orientation(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> Int {
        let result = ((p2.y - p1.y) * (p3.x - p2.x)) - ((p2.x - p1.x) * (p3.y - p2.y))
        //if result == 0.0 {
        //    return 0
        //}
        //if result > 0 {
        //    return 1
        //}
        //return 2

        switch result {
        case 0.0: return 0
        case 0...: return 1
        default: return 2
        }
    }

    func changeOfFloor(floor: Int) {
        //Logger(verbosity: .info).log(message: "Change floor to: \(floor)")
        //self.changeFloorTo = floor
        //
        //if changeFloorTo != 0 {
        //    let portalCheck = findPortalCorrectDir(dir: changeFloorTo)
        //    if let portal = portalCheck != nil ? portalCheck : findNextPortal(dir: changeFloorTo) {
        //        if let tupple = findNextPortalName(nextPortalId: portal.swapLocationToId) {
        //            switchFloorPublisher.send((rtlsOptionsId: tupple.rtlsOptionsId, point: tupple.portalPoint))
        //            self.rtlsOptionId = tupple.rtlsOptionsId
        //            self.changeFloorTo = 0
        //        }
        //    }
        //}
        guard
            floor != 0,
            let portal = findPortalCorrectDir(dir: floor) ?? findNextPortal(dir: floor),
            let tupple = findNextPortalName(nextPortalId: portal.swapLocationToId)
        else { return }
        switchFloorPublisher.send((rtlsOptionsId: tupple.rtlsOptionsId, point: tupple.portalPoint))
    }

    func changeOfFloorIndicator(floor: Int) {
        //walking on new flooor
    }
    //
    //    override fun timeToChangeFloorReset() {
    //    }
}
