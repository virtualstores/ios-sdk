//
// UploadTriggersParameters
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import CoreGraphics

struct UploadTriggersParameters {
    @Inject var config: EnvironmentConfig
    let visitId: Int64
    let requestId: String
    let request: PostTriggerEventRequest
}

extension UploadTriggersParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    var type: RoutingType? { .analytics }
    var method: RequestType { .POST }
    var queryItems: [String: String]? { ["requestId": requestId, "visitId": String(visitId)] }
    var path: String { "/triggerevents" }
    var parametersDictionary: [String: Any]? {
        var parameters = ["name": request.name,
                          "timestamp": request.timeStamp,
                          "userPosition": [
                            "x": Double(request.userPosition.x),
                            "y": Double(request.userPosition.y)
                          ],
                          "tags": request.tags.asDictionary(),
                          "metadata": request.metaData.asDictionary()] as [String: Any]
        
        if let appTrigger = request.appTrigger?.event {
            parameters["appTrigger"] = ["event": appTrigger]
            parameters["triggerType"] = "APP"
        }
        
        if let coordinateTrigger = request.coordinateTrigger {
            parameters["coordinateTrigger"] = [
                "x": Double(coordinateTrigger.point.x),
                "y": Double(coordinateTrigger.point.y),
                "radius": coordinateTrigger.radius
            ]
            parameters["triggerType"] = "COORDINATE"
        }
        
        if let shelfTrigger = request.shelfTrigger {
            parameters["shelfTrigger"] = [
                "shelfGroupId": shelfTrigger.shelfGroupId,
                "shelfId": shelfTrigger.shelfId,
                "shelfTierId": shelfTrigger.shelfTierId
            ]
            parameters["triggerType"] = "SHELF"
        }
        if let zoneTrigger = request.zoneTrigger {
            parameters["zoneTrigger"] = [
                "zoneId": zoneTrigger.zoneId,
                "groupId": zoneTrigger.groupId,
                "type": zoneTrigger.type.rawValue
            ]
            parameters["triggerType"] = "ZONE"
        }
        
        let dict = ["triggerGrps": [request.rtlsOptionsId: [parameters]]]
        
        return dict
    }
}
