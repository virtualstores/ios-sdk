//
// Tree
// VSTT2
//
// Created by Hripsime on 2022-01-23.
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

public class Tree {
    public let root: Zone
    public private(set) var activeZones: [Zone] = []
    public private(set) var floorLevels: [Int: String] = [:]
    
    private let converter: BaseCoordinateConverter
    
    init(root: Zone, converter: BaseCoordinateConverter) {
        self.root = root
        self.converter = converter
    }
    
    public func print() {
        self.root.recursivePrint("")
    }

    var zonesToAdd: [Zone] = []
    public func add(_ floorLevel: Int, _ floorLevelName: String, _ mapZone: MapZone, _ mapZonePoint: MapZonePoint? = nil) {
        if !floorLevels.keys.contains(floorLevel) {
            floorLevels[floorLevel] = floorLevelName
        }
        let splicedSearch = self.searchDelimiter(string: mapZone.name)
        if let id = mapZone.parentId, let zone = self.getZoneWith(id: id) {
            zone.addChild(child: Zone(id: mapZone.id, name: splicedSearch[0], polygon: mapZone.zone, navigationPoint: mapZonePoint?.point, parent: zone, searchTerms: splicedSearch, floorLevel: floorLevel, converter: converter))
        } else if mapZone.parentId != nil {
            self.zonesToAdd.append(Zone(id: mapZone.id, name: splicedSearch[0], polygon: mapZone.zone, navigationPoint: mapZonePoint?.point, parent: nil, searchTerms: splicedSearch, floorLevel: floorLevel, converter: converter))
        } else {
            self.root.addChild(child: Zone(id: mapZone.id, name: splicedSearch[0], polygon: mapZone.zone, navigationPoint: mapZonePoint?.point, parent: nil, searchTerms: splicedSearch, floorLevel: floorLevel, converter: converter))
        }
        self.zonesToAdd.forEach { zone in
            if let id = mapZone.parentId, let parentZone = self.getZoneWith(id: id) {
                zone.parent = parentZone
                parentZone.addChild(child: zone)
                self.zonesToAdd.removeAll(where: { $0 == zone})
            }
        }
    }
    
    public func add(_ floorLevel: Int, _ floorLevelName: String, _ mapZones: [MapZone], _ mapZonesPoints: [MapZonePoint]) {
        for mapZone in mapZones {
            let splicedSearch = self.searchDelimiter(string: mapZone.name)
            let spliced = self.zoneDelimiter(string: splicedSearch[0])
            guard let mapZonePoint = mapZonesPoints.first(where: { $0.name.lowercased() == spliced[0].lowercased() }) else {
                self.add(floorLevel, floorLevelName, mapZone)
                continue
            }
            
            self.add(floorLevel, floorLevelName, mapZone, mapZonePoint)
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

    public func getZonesFor(floorLevel: Int) -> [Zone]? {
        let zones = self.getAllZones()?.all(where: { $0.floorLevel == floorLevel })
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

