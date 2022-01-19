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

    private let visitId: Int64
    private let requestId: String
    private let request: PostTriggerEventRequest

    init(visitId: Int64, requestId: String, request: PostTriggerEventRequest) {
        self.visitId = visitId
        self.requestId = requestId
        self.request = request
    }
}

extension UploadTriggersParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    // Analytics base URL seems different, check if it will be the same after
    // Fix issue and use path for /v2/positions?visitId=\(visitId)&requestId=\(requestId)
    var baseURL: String { "https://gunnis-hp-stat.ih.vs-office.se/api/v2/positions?visitId=\(visitId)&requestId=\(requestId)" }

  //  var path: String { "/v2/positions?visitId=\(visitId)&requestId=\(requestId)" }

    var parameters: [String: Any]? {
        let parameters = ["name": request.name,
                          "timestamp": request.timeStamp,
                          "userPosition": [
                              "x": Double(request.userPosition.x),
                              "y": Double(request.userPosition.y)
                          ],
                          "appTrigger": [
                              "event": request.appTrigger.event
                          ],
                          "tags": [
                              "userId": request.tags.userId,
                              "elapsedTimeInMinutes": request.tags.elapsedTimeInMinutes,
                              "exampleValue3": ""
                          ],
                          "metadata": [
                              "title": request.metaData.title,
                              "description": request.metaData.description,
                              "exampleValue3": ""
                          ]] as [String: Any]

        return parameters
    }

    var headers: [String: String]? { ["apiKey" : "8fc1be06-582e-41ce-b309-61e8fa8e3784" ] }
}
