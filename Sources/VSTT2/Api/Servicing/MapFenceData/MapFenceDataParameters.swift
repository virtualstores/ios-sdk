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

    public init(url: String) {
        self.url = url
    }
}

extension MapFenceDataParameters: Routing {
    /// should be used url, currently the server is returning also .png files that's why for now it's hardcoded
    var baseURL: String { url }
    var headers: [String: String]? { nil }

    var method: RequestType { .GET }
}
