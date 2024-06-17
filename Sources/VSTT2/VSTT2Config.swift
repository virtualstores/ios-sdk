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
    injector.map(DeleteUserService.self) { DeleteUserService(with: NetworkManager()) }
    injector.map(GetUserService.self) { GetUserService(with: NetworkManager()) }
    injector.map(MessagesService.self) { MessagesService(with: NetworkManager()) }
    injector.map(OrdersService.self) { OrdersService(with: NetworkManager()) }
    injector.map(PutUserService.self) { PutUserService(with: NetworkManager()) }
    injector.map(ShelfGroupService.self) { ShelfGroupService(with: NetworkManager()) }
    injector.map(StoresListService.self) { StoresListService(with: NetworkManager()) }
    injector.map(SwapLocationsService.self) { SwapLocationsService(with: NetworkManager()) }
    injector.map(TriggerEventsService.self) { TriggerEventsService(with: NetworkManager()) }
    injector.map(UploadStepEventsService.self) { UploadStepEventsService(with: NetworkManager()) }
    injector.map(UploadSyncEventsService.self) { UploadSyncEventsService(with: NetworkManager()) }
  }

  private func configureRepositories(_ injector: Injector) {
    injector.map(IAnalyticsRepository.self) { AnalyticsRepository() }
    injector.map(IClientRepository.self) { ClientRepository() }
    injector.map(IFloorRepository.self) { FloorRepository() }
    injector.map(IItemsRepository.self) { ItemsRepository() }
    injector.map(IMLRepository.self) { MLRepository() }
    injector.map(IStoreRepository.self) { StoreRepository() }
    injector.map(IUserRepository.self) { UserRepository() }
  }

  private func configureUseCases(_ injector: Injector) {
    // Analytics use cases
    injector.map(CreateVisitUseCase.self) { CreateVisitUseCase() }
    injector.map(GetActiveVisitIDUseCase.self) { GetActiveVisitIDUseCase() }
    injector.map(StopVisitUseCase.self) { StopVisitUseCase() }
    injector.map(UpdateTagsForActiveVisitUseCase.self) { UpdateTagsForActiveVisitUseCase() }
    injector.map(UploadGeopositionsForActiveVisitUseCase.self) { UploadGeopositionsForActiveVisitUseCase() }
    injector.map(UploadPositionsForVisitUseCase.self) { UploadPositionsForVisitUseCase() }
    injector.map(UploadScanEventForActiveVisitUseCase.self) { UploadScanEventForActiveVisitUseCase() }
    injector.map(UploadTriggerEventForActiveVisitUseCase.self) { UploadTriggerEventForActiveVisitUseCase() }

    // Barcode use case
    injector.map(GetPositionByBarcodeUseCase.self) { GetPositionByBarcodeUseCase() }

    // Client use cases
    injector.map(FetchClientsUseCase.self) { FetchClientsUseCase() }
    injector.map(GetActiveClientUseCase.self) { GetActiveClientUseCase() }
    injector.map(GetCachedClientsUseCase.self) { GetCachedClientsUseCase() }
    injector.map(SetActiveClientUseCase.self) { SetActiveClientUseCase() }

    // Event use cases
    injector.map(DecideWhichTriggerEventToDisplayUseCase.self) { DecideWhichTriggerEventToDisplayUseCase() }

    // Floor use cases
    injector.map(CreateCoordinateConvertersUseCase.self) { CreateCoordinateConvertersUseCase() }
    injector.map(FetchMapFenceUseCase.self) { FetchMapFenceUseCase() }
    injector.map(FetchMapZonesUseCase.self) { FetchMapZonesUseCase() }
    injector.map(FetchNavGraphUseCase.self) { FetchNavGraphUseCase() }
    injector.map(FetchShelfGroupsUseCase.self) { FetchShelfGroupsUseCase() }
    injector.map(GetActiveCoordinateConverterUseCase.self) { GetActiveCoordinateConverterUseCase() }
    injector.map(GetActiveFloorUseCase.self) { GetActiveFloorUseCase() }
    injector.map(GetActiveMapFenceUseCase.self) { GetActiveMapFenceUseCase() }
    injector.map(GetActiveMapZonesUseCase.self) { GetActiveMapZonesUseCase() }
    injector.map(GetActiveNavGraphUseCase.self) { GetActiveNavGraphUseCase() }
    injector.map(GetActiveShelfGroupsUseCase.self) { GetActiveShelfGroupsUseCase() }
    injector.map(GetCachedFloorsUseCase.self) { GetCachedFloorsUseCase() }
    injector.map(GetMapZonesUseCase.self) { GetMapZonesUseCase() }
    injector.map(SetActiveFloorUseCase.self) { SetActiveFloorUseCase() }
    injector.map(SetFloorsUseCase.self) { SetFloorsUseCase() }

    // ML use cases
    injector.map(CompileModelUseCase.self) { CompileModelUseCase() }
    injector.map(FetchMLInterfaceVersionsUseCase.self) { FetchMLInterfaceVersionsUseCase() }
    injector.map(GetMLCatalogUseCase.self) { GetMLCatalogUseCase() }
    injector.map(GetMLModelUseCase.self) { GetMLModelUseCase() }
    injector.map(GetMLVersionUseCase.self) { GetMLVersionUseCase() }
    injector.map(GetNLModelUseCase.self) { GetNLModelUseCase() }
    injector.map(GetNLVersionUseCase.self) { GetNLVersionUseCase() }
    injector.map(GetVPSMLModelParamsUseCase.self) { GetVPSMLModelParamsUseCase() }
    injector.map(GetVPSNLModelParamsUseCase.self) { GetVPSNLModelParamsUseCase() }
    injector.map(LoadMLVersionUseCase.self) { LoadMLVersionUseCase() }
    injector.map(LoadNLVersionUseCase.self) { LoadNLVersionUseCase() }
    injector.map(SetMLVersionUseCase.self) { SetMLVersionUseCase() }
    injector.map(SetNLVersionUseCase.self) { SetNLVersionUseCase() }

    // Store use cases
    injector.map(FetchStoreUseCase.self) { FetchStoreUseCase() }
    injector.map(FetchSwapLocationsUseCase.self) { FetchSwapLocationsUseCase() }
    injector.map(GetActiveStoreUseCase.self) { GetActiveStoreUseCase() }
    injector.map(GetCachedStoreUseCase.self) { GetCachedStoreUseCase() }
    injector.map(GetCachedSwapLocationsUseCase.self) { GetCachedSwapLocationsUseCase() }
    injector.map(SetActiveStoreUseCase.self) { SetActiveStoreUseCase() }

    // User use cases
    injector.map(GetUserProfileUseCase.self) { GetUserProfileUseCase() }
    injector.map(SetUserProfileUseCase.self) { SetUserProfileUseCase() }
  }

  private func configureManagers(_ injector: Injector) {
    injector.map(AWSS3UploadManager.self) { AWSS3UploadManager() }
    injector.map(CoordinateEventDetector.self) { CoordinateEventDetector() }
    injector.map(DownloadManager.self) { DownloadManager() }
    injector.map(EventDetector.self) { EventDetector() }
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
    injector.map(IUserManager.self) { UserManager() }
    injector.map(VSMLModelManager.self) { VSMLModelManager() }
    injector.map(VSTT2FloorManager.self) { VSTT2FloorManager() }
    injector.map(ZoneEventDetector.self) { ZoneEventDetector() }
  }

  private func configureHelpers(_ injector: Injector) {
    injector.map(Logger.self) { Logger(verbosity: .debug) }
  }
}
