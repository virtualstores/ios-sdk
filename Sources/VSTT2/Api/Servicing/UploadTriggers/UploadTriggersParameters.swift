//
// UploadTriggersParameters
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import CoreGraphics

public struct UploadTriggersParameters {
    private let config: EnvironmentConfig?
    private let apiKey: String
    private let visitId: Int64
    private let requestId: String
    private let request: PostTriggerEventRequest
    
    init(apiKey: String, visitId: Int64, requestId: String, request: PostTriggerEventRequest, config: EnvironmentConfig?) {
        self.apiKey = apiKey
        self.visitId = visitId
        self.requestId = requestId
        self.request = request
        self.config = config
    }
}

extension UploadTriggersParameters: Routing {
    var environmentConfig: EnvironmentConfig? { config }
    
    var queryItems: [String: String]? {
        let parameters = ["requestId": requestId, "visitId": String(visitId)] as [String: String]
        
        return parameters
    }
    
    var path: String { "/triggerevents" }
    
    var parameters: [String: Any]? {
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
    
    var headers: [String: String]? { ["apiKey" : apiKey ] }
}
