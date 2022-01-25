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
        injector.map(UploadScanEventsService.self) {
            UploadScanEventsService(with: NetworkManager())
        }

        injector.map(UploadPositionsService.self) {
            UploadPositionsService(with: NetworkManager())
        }

        injector.map(UploadTriggersService.self) {
            UploadTriggersService(with: NetworkManager())
        }

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

        injector.map(SwapLocationsService.self) {
            SwapLocationsService(with: NetworkManager())
        }

        injector.map(ShelfGroupService.self) {
            ShelfGroupService(with: NetworkManager())
        }

        injector.map(OrdersService.self) {
            OrdersService(with: NetworkManager())
        }
        
        injector.map(ItemPositionService.self) {
            ItemPositionService(with: NetworkManager())
        }
    }

    private func configureManagers(_ injector: Injector) {
        injector.map(DownloadManager.self) {
            DownloadManager()
        }
        injector.map(Persistence.self) {
            Persistence()
        }

        injector.map(PositionManager.self) {
            PositionManager()
        }

        injector.map(PositionUploadWorker.self) {
            PositionUploadWorker()
        }

        injector.map(TT2NavigationManager.self) {
            TT2NavigationManager()
        }
    }

    private func configureHelpers(_ injector: Injector) {
        injector.map(Logger.self) {
            Logger(verbosity: .debug)
        }
    }
}
