//
// VSTT2Config
// VSTT2
//
// Created by Hripsime on 2021-12-21.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import VSPositionKit

struct VSTT2Config: Config {
    func configure(_ injector: Injector) {
        configureHelpers(injector)
        configureApiEnvironment(injector)
        configureServices(injector)
        configureManagers(injector)
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
        injector.map(CreateVisitsService.self) {
            CreateVisitsService(with: NetworkManager())
        }

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

    private func configureManagers(_ injector: Injector) {
        injector.map(PositionManager.self) {
            PositionManager()
        }
    }

    private func configureHelpers(_ injector: Injector) {
        injector.map(Logger.self) {
            Logger(verbosity: .debug)
        }
    }
}
