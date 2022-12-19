//
// VSTT2Config
// VSTT2
//
// Created by Hripsime on 2021-12-21.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import VSPositionKit
import VSPositionKitTargets

struct VSTT2Config: Config {
    let environment: EnvironmentConfig
  let itemsRepository: ItemsRepository
    let storeRepository: StoreRepository
    public init(environment: EnvironmentConfig) {
        self.environment = environment

        itemsRepository = ItemsRepository(api: ItemsApi(config: environment))
        storeRepository = StoreRepository(api: StoreApi(config: environment))
    }
    
    func configure(_ injector: Injector) {
        configureManagers(injector)
        configureHelpers(injector)
        configureServices(injector)
        configureRepositories(injector)
        configureUseCases(injector)
    }

    private func configureServices(_ injector: Injector) {
        injector.map(EnvironmentConfig.self) {
            environment
        }

        injector.map(UploadScanEventsService.self) {
            UploadScanEventsService(with: NetworkManager())
        }

        injector.map(UploadPositionsService.self) {
            UploadPositionsService(with: NetworkManager())
        }

        injector.map(UploadTriggersService.self) {
            UploadTriggersService(with: NetworkManager())
        }

        injector.map(CreateVisitService.self) {
            CreateVisitService(with: NetworkManager())
        }

        injector.map(StopVisitService.self) {
            StopVisitService(with: NetworkManager())
        }

        injector.map(TagsVisitService.self) {
            TagsVisitService(with: NetworkManager())
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
        
        injector.map(MessagesService.self) {
            MessagesService(with: NetworkManager())
        }

        injector.map(TriggerEventsService.self) {
            TriggerEventsService(with: NetworkManager())
        }

        injector.map(PutUserService.self) {
            PutUserService(with: NetworkManager())
        }

        injector.map(GetUserService.self) {
            GetUserService(with: NetworkManager())
        }

        injector.map(DeleteUserService.self) {
            DeleteUserService(with: NetworkManager())
        }

        injector.map(UploadSyncEventsService.self) {
            UploadSyncEventsService(with: NetworkManager())
        }

        injector.map(UploadStepEventsService.self) {
            UploadStepEventsService(with: NetworkManager())
        }
    }

    private func configureManagers(_ injector: Injector) {
        injector.map(Navigation.self) {
            Navigation(positionManager: PositionManager())
        }
        
        injector.map(DownloadManager.self) {
            DownloadManager()
        }
        
        injector.map(Persistence.self) {
            Persistence()
        }

        injector.map(PositionUploadWorker.self) {
            PositionUploadWorker()
        }
        
        injector.map(VSTT2FloorManager.self) {
            VSTT2FloorManager()
        }
        
        injector.map(MapZoneParser.self) {
            MapZoneParser()
        }
        
        injector.map(TT2ZoneManager.self) {
            TT2ZoneManager()
        }
        
        injector.map(TT2EventManager.self) {
            TT2EventManager()
        }
        
        injector.map(ZoneEventDetector.self) {
            ZoneEventDetector()
        }
        
        injector.map(CoordinateEventDetector.self) {
            CoordinateEventDetector()
        }
        
        injector.map(TT2AnalyticsManager.self) {
            TT2AnalyticsManager()
        }
        
        injector.map(Position.self) {
            Position()
        }
        
//        injector.map(UserSettings.self) {
//            UserSettings()
//        }
        injector.map(UserController.self) {
            UserController()
        }

        injector.map(AWSS3UploadManager.self) {
            AWSS3UploadManager()
        }

        injector.map(RecordingManager.self) {
            RecordingManager()
        }
    }

    private func configureRepositories(_ injector: Injector) {
        injector.map(IItemsRepository.self) {
            itemsRepository
        }

        injector.map(IStoreRepository.self) {
            storeRepository
        }
    }

    private func configureUseCases(_ injector: Injector) {
        injector.map(GetPositionByBarcodeUseCase.self) {
            GetPositionByBarcodeUseCase(storeRepository: storeRepository, itemsRepository: itemsRepository)
        }

        injector.map(FetchStoreUseCase.self) {
            FetchStoreUseCase(repository: storeRepository)
        }

        injector.map(SetActiveStoreUseCase.self) {
            SetActiveStoreUseCase(repository: storeRepository)
        }

        injector.map(GetCachedStoreUseCase.self) {
            GetCachedStoreUseCase(repository: storeRepository)
        }

        injector.map(GetActiveStoreUseCase.self) {
            GetActiveStoreUseCase(repository: storeRepository)
        }
    }

    private func configureHelpers(_ injector: Injector) {
        injector.map(Logger.self) {
            Logger(verbosity: .debug)
        }
    }
}
