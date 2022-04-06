//
// Tree
// VSTT2
//
// Created by Hripsime on 2022-01-23.
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import CoreGraphics

public class Tree {
    public let root: Zone
    public private(set) var activeZones: [Zone] = []
    public internal(set) var currentFloorLevel: Int

    private let converter: BaseCoordinateConverter
    
    init(root: Zone, converter: BaseCoordinateConverter, currentFloorLevel: Int = 0) {
        self.root = root
        self.converter = converter
        self.currentFloorLevel = currentFloorLevel
    }
    
    public func print() {
        self.root.recursivePrint("")
    }

    var zonesToAdd: [Zone] = []
    public func add(_ rtls: RtlsOptions, _ mapZone: MapZone, _ mapZonePoint: MapZonePoint? = nil) {
        let floorLevel = rtls.floorLevel
        let floorLevelName = rtls.name ?? "Floor level name missing"
        if getZoneWith(id: floorLevelName) == nil {
          let width = converter.convertFromMetersToMapCoordinate(input: rtls.widthInMeters)
          let height = converter.convertFromMetersToMapCoordinate(input: rtls.heightInMeters)
          let polygon = [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.0, y: height), CGPoint(x: width, y: height), CGPoint(x: width, y: 0.0)]
          let properties = ZoneProperties(description: nil, id: floorLevelName, name: floorLevelName, names: [], parentId: root.id, fillColor: nil, fillColorSelected: nil, lineColor: nil, lineColorSelected: nil)
          self.root.addChild(child: Zone(id: floorLevelName, properties: properties, polygon: polygon, floorLevel: floorLevel, converter: converter))
        }

        let root: Zone = getZoneWith(id: floorLevelName) ?? self.root
        let parentId = mapZone.properties.parentId
        if let id = parentId, let zone = self.getZoneWith(id: id) {
          zone.addChild(child: Zone(id: mapZone.id, properties: mapZone.properties, polygon: mapZone.zone, navigationPoint: mapZonePoint?.point, parent: zone, floorLevel: floorLevel, converter: converter))
        } else if parentId != nil {
            self.zonesToAdd.append(Zone(id: mapZone.id, properties: mapZone.properties, polygon: mapZone.zone, navigationPoint: mapZonePoint?.point, floorLevel: floorLevel, converter: converter))
        } else {
            root.addChild(child: Zone(id: mapZone.id, properties: mapZone.properties, polygon: mapZone.zone, navigationPoint: mapZonePoint?.point, floorLevel: floorLevel, converter: converter))
        }
        self.zonesToAdd.forEach { zone in
            if let id = parentId, let parentZone = self.getZoneWith(id: id) {
                zone.parent = parentZone
                parentZone.addChild(child: zone)
                self.zonesToAdd.removeAll(where: { $0 == zone})
            }
        }
    }
    
    public func add(_ rtls: RtlsOptions, _ mapZones: [MapZone], _ mapZonesPoints: [MapZonePoint]) {
        for mapZone in mapZones {
            let mapZonePoint = mapZonesPoints.first(where: { $0.parentId == mapZone.id }) ?? mapZonesPoints.first(where: { $0.name.lowercased() == mapZone.properties.name.lowercased() })
            self.add(rtls, mapZone, mapZonePoint)
        }
    }
    
    public func search(string: String?) -> [Zone]? {
        guard let string = string, var zones = self.root.recursiveSearch(string) else {
            return nil
        }
        
        zones.removeAll(where: { $0 == root })
        zones.sort(by: { $0 < $1 })
        
        return zones
    }
    
    public func getAllZones() -> [Zone]? {
        guard var zones = self.root.getChildren() else {
            return nil
        }
        
        zones.removeAll(where: { $0 == root })
        zones.sort(by: { $0 < $1 })
        
        return zones
    }

    public func getZoneWith(id: String) -> Zone? {
      guard let zones = self.getAllZones() else { return nil }
      return zones.first(where: { $0.id == id })
    }

    public func getZonesWith(name: String) -> [Zone]? {
        let zones = self.getAllZones()?.all(where: { $0.name == name && $0.floorLevel == currentFloorLevel })
        
        return zones
    }
    
    public func getZonesFor(floorLevel: Int, includeParent: Bool = false) -> [Zone]? {
        var zones = self.getAllZones()?.all(where: { $0.floorLevel == floorLevel })
        if !includeParent {
            let names = root.children.values.map { $0.name }
            names.forEach { name in
              zones?.removeAll(where: { $0.name == name })
            }
        }
        return zones
    }

    private func zoneDelimiter(string: String) -> [String] {
        let delimiter = ";"
        return string.components(separatedBy: delimiter)
    }
    
    private func searchDelimiter(string: String) -> [String] {
        let delimiter = ":"
        return string.components(separatedBy: delimiter)
    }
}

