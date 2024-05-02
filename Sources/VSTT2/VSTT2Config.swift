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
  let environment: EnvironmentConfig

  init(environment: EnvironmentConfig) {
    self.environment = environment
  }

  func configure(_ injector: Injector) {
    injector.map(EnvironmentConfig.self) { environment }
    configureServices(injector)
    configureRepositories(injector)
    configureUseCases(injector)
    configureManagers(injector)
    configureHelpers(injector)
  }

  private func configureServices(_ injector: Injector) {
    injector.map(ClientsListService.self) { ClientsListService(with: NetworkManager()) }
    injector.map(CreateVisitService.self) { CreateVisitService(with: NetworkManager()) }
    injector.map(DeleteUserService.self) { DeleteUserService(with: NetworkManager()) }
    injector.map(GetUserService.self) { GetUserService(with: NetworkManager()) }
    injector.map(ItemPositionService.self) { ItemPositionService(with: NetworkManager()) }
    injector.map(MLInterfaceVersionsService.self) { MLInterfaceVersionsService(with: NetworkManager()) }
    injector.map(MapFenceDataService.self) { MapFenceDataService(with: NetworkManager()) }
    injector.map(MessagesService.self) { MessagesService(with: NetworkManager()) }
    injector.map(OrdersService.self) { OrdersService(with: NetworkManager()) }
    injector.map(PutUserService.self) { PutUserService(with: NetworkManager()) }
    injector.map(ShelfGroupService.self) { ShelfGroupService(with: NetworkManager()) }
    injector.map(StopVisitService.self) { StopVisitService(with: NetworkManager()) }
    injector.map(StoresListService.self) { StoresListService(with: NetworkManager()) }
    injector.map(SwapLocationsService.self) { SwapLocationsService(with: NetworkManager()) }
    injector.map(TagsVisitService.self) { TagsVisitService(with: NetworkManager()) }
    injector.map(TriggerEventsService.self) { TriggerEventsService(with: NetworkManager()) }
    injector.map(UploadGeoPositionsService.self) { UploadGeoPositionsService(with: NetworkManager()) }
    injector.map(UploadPositionsService.self) { UploadPositionsService(with: NetworkManager()) }
    injector.map(UploadScanEventsService.self) { UploadScanEventsService(with: NetworkManager()) }
    injector.map(UploadStepEventsService.self) { UploadStepEventsService(with: NetworkManager()) }
    injector.map(UploadSyncEventsService.self) { UploadSyncEventsService(with: NetworkManager()) }
    injector.map(UploadTriggersService.self) { UploadTriggersService(with: NetworkManager()) }
  }

  private func configureRepositories(_ injector: Injector) {
    injector.map(IClientRepository.self) { ClientRepository() }
    injector.map(IItemsRepository.self) { ItemsRepository() }
    injector.map(IStoreRepository.self) { StoreRepository() }
  }

  private func configureUseCases(_ injector: Injector) {
    // Client use case
    injector.map(FetchClientsUseCase.self) { FetchClientsUseCase() }
    injector.map(GetActiveClientUseCase.self) { GetActiveClientUseCase() }
    injector.map(GetCachedClientsUseCase.self) { GetCachedClientsUseCase() }
    injector.map(SetActiveClientUseCase.self) { SetActiveClientUseCase() }

    // Barcode use case
    injector.map(GetPositionByBarcodeUseCase.self) { GetPositionByBarcodeUseCase() }

    // Store use case
    injector.map(FetchStoreUseCase.self) { FetchStoreUseCase() }
    injector.map(SetActiveStoreUseCase.self) { SetActiveStoreUseCase() }
    injector.map(GetCachedStoreUseCase.self) { GetCachedStoreUseCase() }
    injector.map(GetActiveStoreUseCase.self) { GetActiveStoreUseCase() }
  }

  private func configureManagers(_ injector: Injector) {
    injector.map(AWSS3UploadManager.self) { AWSS3UploadManager() }
    injector.map(CoordinateEventDetector.self) { CoordinateEventDetector() }
    injector.map(DownloadManager.self) { DownloadManager() }
    injector.map(MapZoneParser.self) { MapZoneParser() }
    injector.map(Navigation.self) { Navigation() }
    injector.map(Persistence.self) { Persistence() }
    injector.map(Position.self) { Position() }
    injector.map(PositionManager.self) { PositionManager() }
    injector.map(PositionUploadWorker.self) { PositionUploadWorker() }
    injector.map(RecordingManager.self) { RecordingManager() }
    injector.map(TT2AnalyticsManager.self) { TT2AnalyticsManager() }
    injector.map(TT2EventManager.self) { TT2EventManager() }
    injector.map(TT2ZoneManager.self) { TT2ZoneManager()}
    injector.map(UserController.self) { UserController() }
    injector.map(VSMLModelManager.self) { VSMLModelManager() }
    injector.map(VSTT2FloorManager.self) { VSTT2FloorManager() }
    injector.map(ZoneEventDetector.self) { ZoneEventDetector() }
  }

  private func configureHelpers(_ injector: Injector) {
    injector.map(Logger.self) { Logger(verbosity: .debug) }
  }
}
