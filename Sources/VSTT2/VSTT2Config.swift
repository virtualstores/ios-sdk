//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-21.
//

import Foundation
import VSFoundation

struct VSTT2Config: Config {
    func configure(_ injector: Injector) {
        configureApiEnvironment(injector)
        configureServices(injector)
    }

    private func configureApiEnvironment(_ injector: Injector) {
        injector.map(EnvironmentConfig.self) {
            EnvironmentConfig(raw: "development")
        }

        injector.map(ClientsListParameters.self) {
            ClientsListParameters()
        }
    }

    private func configureServices(_ injector: Injector) {
        injector.map(ClientsListService.self) {
            ClientsListService(with: NetworkManager())
        }

        injector.map(StoresListService.self) {
            StoresListService(with: NetworkManager())
        }

        injector.map(MapFenceDataService.self) {
            MapFenceDataService(with: NetworkManager())
        }
    }
}
