//
// NavigationSpace
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation

public final class NavigationSpace: Codable {
    
    public let corners: [PointF]?
    public let mapId: Int64
    
    public init(corners: [PointF]?, mapId: Int64) {
        self.corners = corners
        self.mapId = mapId
    }
    
    private enum CodingKeys: String, CodingKey {
        case corners = "navmeshPoints"
        case mapId = "id"
    }
}
