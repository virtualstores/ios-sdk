//
// Tree
// VSTT2
//
// Created by Hripsime on 2022-01-23.
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import CoreGraphics

public class TT2ZonesTree: Disposable {
    @Inject var activeCoordinateConverter: GetActiveCoordinateConverterUseCase
    @Inject var activeFloor: GetActiveFloorUseCase
    @Inject var activeStore: GetActiveStoreUseCase

    private let tag = "TT2ZonesTree"
    private lazy var _root: Zone? = {
      guard
        let id = currentFloorLevelId,
        let converter = converter
      else { return nil }
      let name = (try? activeStore.invoke())?.name ?? "Undefined"
      return Zone(
        id: UUID().uuidString,
        floorLevelId: id,
        properties: ZoneProperties(id: name, name: name, names: [name]),
        converter: converter
      )
    }()
    public var root: Zone {
        guard let root = _root else { fatalError("No root created") }
        return root
    }
    public private(set) var activeZones: [Zone] = []
    private var currentFloorLevelId: Int64? { try? activeFloor.invoke().id }
    private var converter: ICoordinateConverter? { try? activeCoordinateConverter.invoke() }

    deinit {
      Logger(verbosity: .info).log(tag: tag, message: "deinit")
      dispose()
    }

    public func dispose() {
      Logger(verbosity: .info).log(tag: tag, message: "dispose")
      activeZones = []
      zonesToAdd = []
      _root?.dispose()
      _root = nil
    }

    public func log() {
        root.recursiveLog("")
    }

    var zonesToAdd: [Zone] = []
    public func add(_ rtls: RtlsOptions, _ mapZone: MapZone, _ mapZonePoints: [MapZoneCoordinate] = []) {
        guard let converter = converter else { return }
        //if _root == nil {
        //    let name = activeStore.invoke().name
        //    _root = Zone(
        //        id: UUID().uuidString,
        //        floorLevelId: activeFloor.invoke().id,
        //        properties: ZoneProperties(id: name, name: name, names: [name]),
        //        converter: converter
        //    )
        //}
        let floorLevelId = rtls.id
        let floorLevelName = rtls.name ?? "Floor level name missing"
        if getZoneWith(id: floorLevelName) == nil {
            let width = converter.convertFromMetersToMapCoordinate(input: rtls.widthInMeters)
            let height = converter.convertFromMetersToMapCoordinate(input: rtls.heightInMeters)
            let polygon = [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.0, y: height), CGPoint(x: width, y: height), CGPoint(x: width, y: 0.0)]
            let properties = ZoneProperties(description: nil, id: floorLevelName, name: floorLevelName, names: [floorLevelName], parentId: root.id)
            root.addChild(child: Zone(id: floorLevelName, floorLevelId: floorLevelId, properties: properties, polygon: polygon, converter: converter))
        }

        let parentId = mapZone.properties.parentId
        var navigationPoints: [String : (point: CGPoint, properties: PointProperties)] = [:] //mapZonePoints.map { $0.coordinate.fromLatLngToMeter(converter: converter) }
        mapZonePoints.forEach { navigationPoints[$0.description] = ($0.coordinate.fromLatLngToMeter(converter: converter), $0.properties) }
        if let id = parentId, let zone = getZoneWith(id: id) {
            zone.addChild(child: Zone(id: mapZone.id, floorLevelId: floorLevelId, properties: mapZone.properties, polygon: mapZone.zone, navigationPoints: navigationPoints, parent: zone, converter: converter))
        } else if parentId != nil {
            zonesToAdd.append(Zone(id: mapZone.id, floorLevelId: floorLevelId, properties: mapZone.properties, polygon: mapZone.zone, navigationPoints: navigationPoints, converter: converter))
        } else {
            (getZoneWith(id: floorLevelName) ?? root).addChild(
              child: Zone(id: mapZone.id, floorLevelId: floorLevelId, properties: mapZone.properties, polygon: mapZone.zone, navigationPoints: navigationPoints, converter: converter),
              linkParent: false
            )
        }
        zonesToAdd.forEach { (zone) in
            if let id = parentId, let parentZone = getZoneWith(id: id) {
                parentZone.addChild(child: zone)
                zonesToAdd.removeAll(where: { $0 == zone})
            }
        }
    }
    
    public func add(_ rtls: RtlsOptions, _ mapZones: [MapZone], _ mapZonesPoints: [MapZoneCoordinate]) {
        mapZones.forEach { (mapZone) in
            add(rtls, mapZone, mapZonesPoints.all(where: { $0.parentId == mapZone.id }))
        }
    }
    
    public func search(string: String?) -> [Zone]? {
        guard let string = string, var zones = root.recursiveSearch(string) else { return nil }
        zones.removeAll(where: { $0 == root })
        zones.sort(by: { $0 < $1 })
        return zones
    }
    
    public func getAllZones() -> [Zone]? {
        guard var zones = root.getChildren() else { return nil }
        zones.removeAll(where: { $0 == root })
        zones.sort(by: { $0 < $1 })
        return zones
    }

    public func getZoneWith(id: String) -> Zone? {
        getAllZones()?.first(where: { $0.id == id })
    }

    public func getZonesWith(name: String) -> [Zone]? {
        getAllZones()?.all(where: { $0.name == name && $0.floorLevelId == currentFloorLevelId })
    }
    
    public func getZonesFor(floorLevelId: Int64, includeParent: Bool = false) -> [Zone]? {
        var zones = getAllZones()?.all(where: { $0.floorLevelId == floorLevelId })
        if !includeParent {
            root.children.values.map({ $0.name }).forEach({ (name) in zones?.removeAll(where: { $0.name == name }) })
        }
        return zones
    }

    public func getZonesForCurrentFloorLevel() -> [Zone]? {
        guard let id = currentFloorLevelId else { return nil }
        return getZonesFor(floorLevelId: id)
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
