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
    @Inject var config: EnvironmentConfig

    private let apiKey: String
    private let visitId: Int64
    private let requestId: String
    private let request: PostTriggerEventRequest

    init(apiKey: String, visitId: Int64, requestId: String, request: PostTriggerEventRequest) {
        self.apiKey = apiKey
        self.visitId = visitId
        self.requestId = requestId
        self.request = request
    }
}

extension UploadTriggersParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    var queryItems: [String: String]? {
        let parameters = ["visitId": String(visitId), "requestId": requestId] as [String: String]

        return parameters
    }

    var path: String { "/positions" }

    var parameters: [String: Any]? {
        let parameters = ["name": request.name,
                          "timestamp": request.timeStamp,
                          "userPosition": [
                              "x": Double(request.userPosition.x),
                              "y": Double(request.userPosition.y)
                          ],
                          "appTrigger": [
                              "event": request.appTrigger?.event
                          ],
                          "tags": [
                              "userId": request.tags?.userId,
                              "elapsedTimeInMinutes": request.tags?.elapsedTimeInMinutes,
                              "exampleValue3": ""
                          ],
                          "metadata": [
                              "title": request.metaData?.title,
                              "description": request.metaData?.description,
                              "exampleValue3": ""
                          ]] as [String: Any]

        return parameters
    }

    var headers: [String: String]? { ["apiKey" : apiKey ] }
}
