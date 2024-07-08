//
//  InAndOut.swift
//
//
//  Created by Théodore Roos on 2024-05-16.
//

import Foundation

protocol IInAndOutTrigger {
  var id: String { get }
}

protocol IInAndOutDelegate: AnyObject {
  func onEnter(trigger: IInAndOutTrigger, position: CGPoint)
  func onExit(trigger: IInAndOutTrigger, position: CGPoint)
  func onEnter(triggers: [IInAndOutTrigger], position: CGPoint)
  func onExit(triggers: [IInAndOutTrigger], position: CGPoint)
}

class InAndOut {
  let triggers: [IInAndOutTrigger]
  weak var delegate: IInAndOutDelegate?

  private var activeInside: [IInAndOutTrigger] = []

  init(triggers: [IInAndOutTrigger]) {
    self.triggers = triggers
  }

  deinit {
    delegate = nil
  }

  func add(delegate: IInAndOutDelegate) {
    self.delegate = delegate
  }

  func reset() {
    activeInside.removeAll()
  }

  func onNewPosition(currentPosition: CGPoint) {
    var enterEvents = [IInAndOutTrigger]()
    var exitEvents = [IInAndOutTrigger]()
    triggers.forEach { (trigger) in
      switch trigger {
      case let type as Radius:
        if isWithinRadius(position: currentPosition, trigger: type) {
          if isNotActive(trigger: trigger, position: currentPosition) {
            enterEvents.append(trigger)
          }
        } else if isActive(trigger: trigger, position: currentPosition) {
          exitEvents.append(trigger)
        }
      case let type as Zone:
        if isPointInside(point: currentPosition, coordinates: type.polygon) {
          if isNotActive(trigger: trigger, position: currentPosition) {
            enterEvents.append(trigger)
          }
        } else if isActive(trigger: trigger, position: currentPosition) {
          exitEvents.append(trigger)
        }
      default: break
      }
    }

    delegate?.onEnter(triggers: enterEvents, position: currentPosition)
    delegate?.onExit(triggers: exitEvents, position: currentPosition)
  }

  private func isNotActive(trigger: IInAndOutTrigger, position: CGPoint) -> Bool {
    guard !activeInside.contains(where: { $0.id == trigger.id }) else { return false }
    activeInside.append(trigger)
    delegate?.onEnter(trigger: trigger, position: position)
    return true
  }

  private func isActive(trigger: IInAndOutTrigger, position: CGPoint) -> Bool {
    guard activeInside.contains(where: { $0.id == trigger.id }) else { return false }
    activeInside.removeAll(where: { $0.id == trigger.id })
    delegate?.onExit(trigger: trigger, position: position)
    return true
  }

  private func isWithinRadius(position: CGPoint, trigger: Radius) -> Bool {
    ((pow(position.x - trigger.centerPoint.x, 2) + pow(position.y - trigger.centerPoint.y, 2)) <= pow(trigger.radius, 2))
  }

  // Region isPointInside
  private func isPointInside(point: CGPoint, coordinates: [CGPoint]) -> Bool {
    var intersectCount = 0
    for coordinate in 0..<coordinates.count - 1 {
      if (intersectsLine(
        linePoint1: coordinates[coordinate],
        linePoint2: coordinates[coordinate + 1],
        pee: point
      )) {
        intersectCount += 1
      }
    }
    if (coordinates[0] != coordinates.last) {
      if (intersectsLine(
        linePoint1: coordinates[0],
        linePoint2: coordinates.last!,
        pee: point
      )) {
        intersectCount += 1 // Checks line from last point to first point
      }
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
  // Endregion isPointInside

  struct Radius: IInAndOutTrigger {
    let id: String
    let centerPoint: CGPoint
    let radius: Double
  }

  struct Zone: IInAndOutTrigger {
    let id: String
    let zoneId: String
    let polygon: [CGPoint]
  }
}
