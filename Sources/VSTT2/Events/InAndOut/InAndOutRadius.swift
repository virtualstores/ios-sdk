//
//  InAndOutRadius.swift
//  
//
//  Created by Théodore Roos on 2022-03-14.
//

import Foundation
import CoreGraphics

protocol InAndOutRadiusDelegate {
    func onEnter(trigger: InAndOutRadius.Trigger, position: CGPoint)
    func onExit(trigger: InAndOutRadius.Trigger, position: CGPoint)
}

class InAndOutRadius {
    let triggers: [Trigger]
    var delegate: InAndOutRadiusDelegate?
    private var activeInside: [Trigger] = []

    init(triggers: [Trigger]) {
      self.triggers = triggers
    }

    func add(delegate: InAndOutRadiusDelegate) {
        self.delegate = delegate
    }

    func removeDelegate() {
        self.delegate = nil
    }

    func onNewPosition(currentPosition: CGPoint) {
        triggers.forEach { trigger in
            if (isWithinRadius(position: currentPosition, trigger: trigger)) {
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

    private func isWithinRadius(position: CGPoint,trigger: Trigger) -> Bool {
        ((pow(position.x - trigger.centerPoint.x, 2) + pow(position.y - trigger.centerPoint.y, 2)) <= pow(trigger.radius, 2))
    }

    func onDestroy() {

    }

    struct Trigger{
        let id: String
        let centerPoint: CGPoint
        let radius: Double
    }
}
