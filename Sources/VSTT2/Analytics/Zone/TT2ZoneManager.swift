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
import ios_position_kit_sdk

///ZoneManager is helping handle in-out events
public class TT2ZoneManager: TT2Zone {
    public var zoneEnteredPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
    public var zoneExitedPublisher: CurrentValueSubject<TriggerEvent?, Never> = .init(nil)
    
    private var rtlsOptions: RtlsOptions?
    private var zonesPoint: [[CGPoint]] = []
    private var zones: [Zone] = []
    private var insideZones: [String: [CGPoint]] = [:]
    private var activeInside: [[CGPoint]] = []
    
    init() {}
    
    func setup(with zones: [Zone], rtlsOptions: RtlsOptions) {
        self.rtlsOptions = rtlsOptions
        self.zones = zones
        
        zones.forEach({ zone in
            zonesPoint.append(zone.points)
        })
    }
    
    public func onNewPosition(currentPosition: CGPoint) {
        zonesPoint.forEach { polygon in
            if isPointInside(point: currentPosition, coordinates: polygon) {
                if !self.activeInside.contains(polygon) {
                    if let event = createZoomEnteredEvent(for: currentPosition, polygon: polygon) {
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
    
    
    private func createZoomEnteredEvent(for currentPosition: CGPoint, polygon: [CGPoint]) -> TriggerEvent? {
        guard let zone = zones.first(where: { $0.points == polygon }), let rtlsOptions = self.rtlsOptions else { return nil }
        
        let groupId = UUID().uuidString.uppercased()
        insideZones[groupId] = zone.polygon
        
        let zoneTrigger = TriggerEvent.EventType.zoneTrigger(TriggerEvent.ZoneTrigger(zoneId: zone.name, groupId: groupId, type: .enter))
        return TriggerEvent(rtlsOptionsId: String(rtlsOptions.id), name: zone.name, description: "", timestamp: Date(),
                            userPosition: currentPosition, eventType: zoneTrigger)
    }
    
    private func exitZone(for currentPosition: CGPoint, polygon: [CGPoint]){
        guard let zone = zones.first(where: { $0.points == polygon }), let rtlsOptions = self.rtlsOptions else { return }
        insideZones.forEach { (key, value) in
            guard value == zone.polygon else { return }
            
            let zoneTrigger = TriggerEvent.EventType.zoneTrigger(TriggerEvent.ZoneTrigger(zoneId: zone.name, groupId: key, type: .exit))
            
            let event = TriggerEvent(rtlsOptionsId: String(rtlsOptions.id),name: zone.name, description: "", timestamp: Date(),
                                     userPosition: currentPosition, eventType: zoneTrigger)
            
            zoneExitedPublisher.send(event)
            self.activeInside.removeAll(where: { $0 == polygon })
        }
    }
}
