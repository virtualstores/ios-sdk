//
// NavigationSpaceParameters
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation

public struct NavigationSpaceParameters {
    let mapId: String
    
    public init(mapId: String) {
        self.mapId = mapId
    }
}

extension NavigationSpaceParameters: Routing {
    var method: RequestType {
        return .GET
    }

    var routPath: String {
        return "/api/v2/navmesh/maps/\(mapId)"
    }
}

