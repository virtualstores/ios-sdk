//
// Zone
// VSTT2
//
// Created by Hripsime on 2022-02-22
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics
import UIKit
import VSFoundation

public class Zone: Equatable {
    public let name: String
    public let id: String
    public let floorLevel: Int
    public var color: UIColor = .white
    public var image: UIImage?
    public internal(set) var polygon: [CGPoint]
    public internal(set) var parent: Zone?
    public internal(set) var children: Dictionary<String, Zone>
    public internal(set) var searchTerms: [String]
    internal var navigationPoint: CGPoint?
    private let converter: BaseCoordinateConverter

    private var bezierPath: UIBezierPath?

    init(id:String, name: String, polygon: [CGPoint] = [], navigationPoint: CGPoint? = nil, parent: Zone? = nil, children: Dictionary<String, Zone> = [:], searchTerms: [String] = [], floorLevel: Int, converter: BaseCoordinateConverter) {
        self.id = id
        self.name = name
        self.polygon = polygon
        self.navigationPoint = navigationPoint
        self.parent = parent
        self.children = children
        self.searchTerms = searchTerms
        self.floorLevel = floorLevel
        self.converter = converter
    }
    
    var points: [CGPoint] {
        var points: [CGPoint] = []
        for point in polygon {
            points.append(CGPoint(x: converter.convertFromMapCoordinateToMeters(input: point.x), y: converter.convertFromMapCoordinateToMeters(input: point.y)))
        }
        return points
    }
    
    func addChild(child: Zone) {
        let zone = Zone(id: child.id, name: child.name, polygon: child.polygon, navigationPoint: child.navigationPoint, parent: self, searchTerms: child.searchTerms, floorLevel: child.floorLevel, converter: converter)
        self.children[child.name] = zone
    }
    
    func getChildren() -> [Zone]? {
        var list: [Zone] = []
        
        list.append(self)
        
        for key in self.children.keys {
            if let zones = self.children[key]?.getChildren() {
                list += zones
            }
        }
        
        return !list.isEmpty ? list : nil
    }
    
    func recursivePrint(_ padding: String) {
        Logger.init(verbosity: .debug).log(message: "\(padding)\(self.name)")
        
        for key in self.children.keys {
            self.children[key]?.recursivePrint(padding + "    ")
        }
    }
    
    func recursiveSearch(_ searchString: String) -> [Zone]? {
        var list: [Zone] = []
        
        var search: String = self.name
        
        for string in searchTerms {
            search = search + ":" + string
        }
        
        if search.lowercased().contains(searchString.lowercased()) {
            list.append(self)
        }
        
        for key in self.children.keys {
            if let zones = self.children[key]?.recursiveSearch(searchString) {
                list += zones
            }
        }
        
        return !list.isEmpty ? list : nil
    }
    
    func contains(point: CGPoint) -> Bool {
        if self.bezierPath == nil {
            guard points.count > 0 else {
                return false
            }
            
            let path = UIBezierPath()
            path.move(to: points[0])
            for point in points {
                path.addLine(to: point)
            }
            path.close()
            self.bezierPath = path
        }
        
        guard let path = self.bezierPath else {
            return false
        }
        
        return path.contains(point)
    }

    /// Uses name parameter for comparison
    public static func == (lhs: Zone, rhs: Zone) -> Bool {
        lhs.name == rhs.name
    }
    
    /// Uses name parameter for comparison
    public static func < (lhs: Zone, rhs: Zone) -> Bool {
        lhs.name < rhs.name
    }
}
