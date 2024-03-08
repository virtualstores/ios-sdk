//
// TT2ZOneManager
// VSTT2
//
// Created by Hripsime on 2022-02-22
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import Combine
import VSFoundation

///ZoneManager is helping handle in-out events
public class TT2ZoneManager: TT2Zone {
    public var zoneEnteredPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
    public var zoneExitedPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
    var onEnterPublisher: CurrentValueSubject<Zone?, Never> = .init(nil)
    var onExitPublisher: CurrentValueSubject<Zone?, Never> = .init(nil)
    
    private var rtlsOptions: RtlsOptions?
    private var zones: [Zone] = []
    private var zonesPoint: [[CGPoint]] = []
    private var entryPoints: [String: [TriggerEvent.ZoneTrigger.EntryPoint]] = [:]
    private var insideZones: [String: [CGPoint]] = [:]
    private var activeInside: [[CGPoint]] = []
    private var positionHistory: Queue<CGPoint> = Queue(maxSize: 6)

    init() {}
    
    func setup(with zones: [Zone], rtlsOptions: RtlsOptions) {
        self.rtlsOptions = rtlsOptions
        self.zones = zones
        
        zones.forEach({ (zone) in
            zonesPoint.append(zone.points)
            entryPoints[zone.name] = zone.entryPoints.map({ .init(line: $0.line, id: $0.id) })
        })
    }
    
    public func onNewPosition(currentPosition: CGPoint) {
        positionHistory.enqueue(currentPosition)
        zonesPoint.forEach { polygon in
            if isPointInside(point: currentPosition, coordinates: polygon) {
                if !self.activeInside.contains(polygon) {
                    if let event = createZoneEnteredEvent(for: currentPosition, polygon: polygon) {
                        self.activeInside.append(polygon)
                        self.zoneEnteredPublisher.send(event)
                    }
                }
            } else {
                if self.activeInside.contains(polygon) {
                    exitZone(for: currentPosition, polygon: polygon)
                }
            }
        }
    }
    
    public func stopped(currentPosition: CGPoint) {
        self.activeInside.forEach { (polygon) in
            exitZone(for: currentPosition, polygon: polygon)
        }
    }
    
    private func isPointInside(point: CGPoint, coordinates: [CGPoint]) -> Bool {
        var intersectCount = 0
        for i in 0..<coordinates.count - 1 {
            if intersectsLine(pointOne: coordinates[i], pointTwo: coordinates[i+1], pee: point) { intersectCount += 1 }
        }
        if let last = coordinates.last, coordinates[0] != last {
            if intersectsLine(pointOne: coordinates[0], pointTwo: last, pee: point) { intersectCount += 1 }
        }

        return intersectCount % 2 == 1
    }
    
    private func intersectsLine(pointOne: CGPoint, pointTwo: CGPoint, pee: CGPoint) -> Bool {
        let horizontalPoint = CGPoint(x: .greatestFiniteMagnitude, y: pee.y)
        
        let o1 = orientation(p1: pointOne, p2: pointTwo, p3: pee)
        let o2 = orientation(p1: pointOne, p2: pointTwo, p3: horizontalPoint)
        let o3 = orientation(p1: pee, p2: horizontalPoint, p3: pointOne)
        let o4 = orientation(p1: pee, p2: horizontalPoint, p3: pointTwo)
        
        var result = false
        if o1 != o2 && o3 != o4 {
            result = true
        }
        return result
    }
    
    private func orientation(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> Int {
        let result = ((p2.y - p1.y) * (p3.x - p2.x)) - ((p2.x - p1.x) * (p3.y - p2.y))
        if result == 0 {
            return 0
        }
        if result > 0 {
            return 1
        }
        return 2
    }
    
    
    private func createZoneEnteredEvent(for currentPosition: CGPoint, polygon: [CGPoint]) -> TriggerEvent? {
        guard let zone = zones.first(where: { $0.points == polygon }), let rtlsOptions = self.rtlsOptions else { return nil }
        onEnterPublisher.send(zone)
        
        let groupId = UUID().uuidString.uppercased()
        insideZones[groupId] = zone.polygon
        
        let zoneTrigger = TriggerEvent.EventType.zoneTrigger(TriggerEvent.ZoneTrigger(zoneId: zone.name, groupId: groupId, type: .enter, entryPoint: checkForZoneEntryPoint(entryPoints: entryPoints[zone.name] ?? [], positions: positionHistory.asArray())))
        return TriggerEvent(rtlsOptionsId: rtlsOptions.id, name: zone.name, description: "", eventType: zoneTrigger, timestamp: Date(), userPosition: currentPosition)
    }
    
    private func exitZone(for currentPosition: CGPoint, polygon: [CGPoint]) {
        guard let zone = zones.first(where: { $0.points == polygon }), let rtlsOptions = self.rtlsOptions else { return }
        onExitPublisher.send(zone)
        insideZones.forEach { (key, value) in
            guard value == zone.polygon else { return }
            
            let zoneTrigger = TriggerEvent.EventType.zoneTrigger(TriggerEvent.ZoneTrigger(zoneId: zone.name, groupId: key, type: .exit, entryPoint: checkForZoneEntryPoint(entryPoints: entryPoints[zone.name] ?? [], positions: positionHistory.asArray())))
            let event = TriggerEvent(rtlsOptionsId: rtlsOptions.id,name: zone.name, description: "", eventType: zoneTrigger, timestamp: Date(), userPosition: currentPosition)

            zoneExitedPublisher.send(event)
            self.activeInside.removeAll(where: { $0 == polygon })
            self.insideZones.removeValue(forKey: key)
        }
    }

    func checkForZoneEntryPoint(entryPoints: [TriggerEvent.ZoneTrigger.EntryPoint], positions: [CGPoint]) -> TriggerEvent.ZoneTrigger.EntryPoint? {
      // Validate positions
      for i in 0..<positions.count - 1 {
        if positions[i].distance(to: positions[i + 1]) > 1 {
          return nil
        }
      }
      
      return entryPoints.first(where: { (entryPoint) in
        for i in 0..<positions.count - 1 {
          if linesCross(start1: entryPoint.line[0], end1: entryPoint.line[1], start2: positions[i], end2: positions[i + 1]) {
            return true
          }
        }
        return false
      })
    }

    func linesCross(start1: CGPoint, end1: CGPoint, start2: CGPoint, end2: CGPoint) -> Bool {
      // Calculate the differences between the start and end X/Y positions for each of our points
      let delta1x = end1.x - start1.x
      let delta1y = end1.y - start1.y
      let delta2x = end2.x - start2.x
      let delta2y = end2.y - start2.y

      // Create a 2D matrix from our vectors and calculate the determinant
      let determinant = delta1x * delta2y - delta2x * delta1y

      if (abs(determinant) < 0.0001) {
        // If the determinant is effectively zero then the lines are parallel/colinear
        return false
      }

      // If the coefficients both lie between 0 and 1 then we have an intersection
      let ab = ((start1.y - start2.y) * delta2x - (start1.x - start2.x) * delta2y) / determinant

      if (ab > 0 && ab < 1) {
        let cd = ((start1.y - start2.y) * delta1x - (start1.x - start2.x) * delta1y) / determinant

        if (cd > 0 && cd < 1) {
          // Lines cross – figure out exactly where and return it
          return true
        }
      }

      // Lines don't cross
      return false
    }
}
