//
// MapFenceDataParameters
// VSTT2
//
// Created by Hripsime on 2021-12-21
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public struct MapFenceDataParameters {
    private let url: String

    @Inject var config: EnvironmentConfig

    public init(url: String) {
        self.url = url
    }
}

extension MapFenceDataParameters: Routing {
    var environmentConfig: EnvironmentConfig { config }

    /// should be used url, currently the server is returning also .png files that's why for now it's hardcoded
    var baseURL: String {
        "https://virtualstores-navdata.s3.eu-north-1.amazonaws.com/beijer/lidingo/mapfence.json" }
    var headers: [String: String]? { nil }
    
    var method: RequestType { .GET }
}
