import Foundation
import UIKit

public struct NavigationSpaceInfo {
    public let id: Int64
    public let name: String
}

public enum MapType {
    case url(URL)
    case image(UIImage)
}

// TODO: Gör till ett protokoll som Store implementerar?
public struct NavigationSpace {
    public let id: Int64
    public let name: String
    public let floorLevel: Int

    public let mapType: MapType
    public let mapfence: Data?
    public let mapFenceImage: UIImage?
    public let navgraph: Data
    public let offsetZones: Data?
    public let mapZones: [MapZone]
    public let mapZonePoints: [MapZonePoint]
    public let size: CGSize

    public var width: Double {
        Double(size.width)
    }

    public var height: Double {
        Double(size.height)
    }

    public let startCodes: [PositionedCode]
    public let stopCodes: [PositionedCode]

    public let navigation: NavigationData

    public init(id: Int64, name: String, floorLevel: Int, mapType: MapType, mapfence: Data?, mapFenceImage: UIImage?, navgraph: Data, offsetZones: Data? = nil, mapZones: [MapZone], mapZonePoints: [MapZonePoint], size: CGSize, startCodes: [PositionedCode], stopCodes: [PositionedCode], navigation: NavigationData) {
        self.id = id
        self.name = name
        self.floorLevel = floorLevel

        self.mapType = mapType
        self.mapfence = mapfence
        self.mapFenceImage = mapFenceImage
        self.navgraph = navgraph
        self.mapZones = mapZones
        self.mapZonePoints = mapZonePoints
        self.offsetZones = offsetZones
        self.size = size

        self.startCodes = startCodes
        self.stopCodes = stopCodes

        self.navigation = navigation
    }
}
