//
//  UploadPositionsParameters
//  
//
//  Created by Hripsime on 2022-01-13.
//

import Foundation
import VSFoundation

public struct UploadPositionsParameters {
    @Inject var config: EnvironmentConfig

    private let visitId: Int64
    private let requestId: String
    private let positionGrps: [String: [RecordedPosition]]

    init(visitId: Int64, requestId: String, positionGrps: [String: [RecordedPosition]]) {
        self.visitId = visitId
        self.requestId = requestId
        self.positionGrps = positionGrps
    }
}

extension UploadPositionsParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    // Analytics base URL seems different, check if it will be the same after
    var baseURL: String { "https://gunnis-hp-stat.ih.vs-office.se/api" }

    var method: RequestType { .POST }

    var path: String { "/v2/positions?visitId=\(visitId)&requestId=\(requestId)" }

    var parameters: [String: Any]? {
        let parameters = ["positionGrps": positionGrps] as [String: Any]

        return parameters
    }

    var headers: [String: String]? { ["apiKey" : "8fc1be06-582e-41ce-b309-61e8fa8e3784" ] }
}
