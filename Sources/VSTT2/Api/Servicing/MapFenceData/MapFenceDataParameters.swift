//
// MapFenceDataParameters
// VSTT2
//
// Created by Hripsime on 2021-12-21
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

struct MapFenceDataParameters {
    let url: String
}

extension MapFenceDataParameters: Routing {
    var environmentConfig: EnvironmentConfig? { nil }
    var type: RoutingType { .unknown }
    var method: RequestType { .GET }
    var path: String { "" }
    /// should be used url, currently the server is returning also .png files that's why for now it's hardcoded
    var baseURL: String { url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url }
    var headers: [String: String]? { nil }
}
