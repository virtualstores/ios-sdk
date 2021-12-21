//
// EnvironmentConfig
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

/// Here we can have all setups depended what we need to use for each environment
enum EnvironmentConfig: String {
    init?(raw: String) {
        self.init(rawValue: raw)
    }

    case production
    case development

    func baseURL() -> String {
        switch self {
        case .production:
            return "https://PROD.virtualstores.se"
        case .development:
            return "https://gunnis-hp-central.ih.vs-office.se/api/v1"
        }
    }
}
