//
//  InAndOutZone.swift
//  
//
//  Created by Théodore Roos on 2022-03-14.
//

import Foundation
import CoreGraphics

protocol InAndOutZoneDelegate {
    func onEnter(trigger: InAndOutZone.Trigger, position: CGPoint)
    func onExit(trigger: InAndOutZone.Trigger, position: CGPoint)
}

class InAndOutZone {
    let triggers: [Trigger]
    var delegate: InAndOutZoneDelegate?
    private var activeInside: [Trigger] = []

    init(triggers: [Trigger]) {
      self.triggers = triggers
    }

    func add(delegate: InAndOutZoneDelegate) {
        self.delegate = delegate
    }
    func removeDelegate() {
        self.delegate = nil
    }

    func onNewPosition(currentPosition: CGPoint) {
        triggers.forEach { trigger in
            if (isPointInside(point: currentPosition, coordinates: trigger.polygon)) {
              if !activeInside.contains(where: { $0.id == trigger.id }) {
                    delegate?.onEnter(trigger: trigger, position: currentPosition)
                    activeInside.append(trigger)
                }
            } else {
                if activeInside.contains(where: { $0.id == trigger.id }) {
                    delegate?.onExit(trigger: trigger, position: currentPosition)
                    activeInside.removeAll(where: { $0.id == trigger.id })
                }
            }
        }
    }

    //region isPointInside

    private func isPointInside(point: CGPoint, coordinates: [CGPoint]) -> Bool {
        var intersectCount = 0
        for coordinate in 0..<coordinates.count - 1 {
            if (intersectsLine(
              linePoint1: coordinates[coordinate],
              linePoint2: coordinates[coordinate + 1],
              pee: point
                )
            ) { intersectCount += 1 }
        }
        if (coordinates[0] != coordinates.last!) {
            if (intersectsLine(
              linePoint1: coordinates[0],
              linePoint2: coordinates.last!,
              pee: point
                )
            ) { intersectCount += 1 } // checks line from last point to first point
        }
        return intersectCount % 2 == 1
    }

    private func intersectsLine(linePoint1: CGPoint, linePoint2: CGPoint, pee: CGPoint) -> Bool {
        let horizontalPoint = CGPoint(x: .greatestFiniteMagnitude, y: pee.y)
        let o1 = orientation(p1: linePoint1, p2: linePoint2, p3: pee)
        let o2 = orientation(p1: linePoint1, p2: linePoint2, p3: horizontalPoint)
        let o3 = orientation(p1: pee, p2: horizontalPoint, p3: linePoint1)
        let o4 = orientation(p1: pee, p2: horizontalPoint, p3: linePoint2)

        var result = false
        if (o1 != o2 && o3 != o4) {
            result = true
        }
        return result
    }

    private func orientation(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> Int {
        let result = ((p2.y - p1.y) * (p3.x - p2.x)) - ((p2.x - p1.x) * (p3.y - p2.y))
        if (result == 0) {
            return 0
        }
        if (result > 0) {
            return 1
        }
        return 2
    }
    //endregion isPointInside

    func onDestroy() {

    }

    struct Trigger {
        let id: String
        let polygon: [CGPoint]
    }
}
