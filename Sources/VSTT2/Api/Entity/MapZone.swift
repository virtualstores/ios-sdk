import Foundation
import CoreGraphics

public struct MapZone {
    public let id: Int
    public let name: String
    public let zone: [CGPoint]
    
    public init(id: Int, name: String, zone: [CGPoint]) {
        self.id = id
        self.name = name
        self.zone = zone
    }
}

public struct MapZonePoint {
    public let name: String
    public let point: CGPoint
    
    public init(name: String, point: CGPoint) {
        self.name = name
        self.point = point
    }
}
