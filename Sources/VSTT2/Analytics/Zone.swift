//
//  File.swift
//  
//
//  Created by Hripsime on 2022-02-22.
//

import Foundation
import CoreGraphics
import UIKit

public class Zone: Equatable {
    public let name: String
    public internal(set) var polygon: [CGPoint]
    internal var navigationPoint: CGPoint?
    public let id: String
    public let parent: Zone?
    public internal(set) var children: Dictionary<String, Zone>
    public internal(set) var searchTerms: [String]
    public let floorLevel: Int
    public var color: UIColor = .white
    public var image: UIImage?
    
    init(id:String, name: String, polygon: [CGPoint] = [], navigationPoint: CGPoint? = nil, parent: Zone? = nil, children: Dictionary<String, Zone> = [:], searchTerms: [String] = [], floorLevel: Int) {
        self.id = id
        self.name = name
        self.polygon = polygon
        self.navigationPoint = navigationPoint
        self.parent = parent
        self.children = children
        self.searchTerms = searchTerms
        self.floorLevel = floorLevel
    }
    
    var points: [CGPoint] {
        var points: [CGPoint] = []
        for point in polygon {
           // points.append(CGPoint(x: TT2.shared.converter.convertFromMapCoordinate(point.x), y: TT2.shared.converter.convertFromMapCoordinate(point.y)))
        }
        return points
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
