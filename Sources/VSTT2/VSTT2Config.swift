//
// VSTT2Config
// VSTT2
//
// Created by Hripsime on 2021-12-21.
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import VSPositionKit

class VSTT2Config: Config {
  let environment: EnvironmentConfig

  var disposables = [Disposable]()

  init(environment: EnvironmentConfig) {
    self.environment = environment
  }

  func dispose() {
    // TODO:
  }

  func configure(_ injector: Injector) {
    injector.map(EnvironmentConfig.self) { self.environment }
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
    injector.map(IAnalyticsRepository.self) { [weak self] in
      let inject = AnalyticsRepository()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(IApiKeyRepository.self) { ApiKeyRepository() }
    injector.map(IAuthRepository.self) { AuthRepository()}
    injector.map(IClientRepository.self) { [weak self] in
      let inject = ClientRepository()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(IFloorRepository.self) { [weak self] in
      let inject = FloorRepository()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(IItemsRepository.self) { [weak self] in
      let inject = ItemsRepository()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(IJWTTokenRepository.self) { JWTTokenRepository() }
    injector.map(IMLRepository.self) { [weak self] in
      let inject = MLRepository()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(IStatusRepository.self) { StatusRepository() }
    injector.map(IStoreRepository.self) { [weak self] in
      let inject = StoreRepository()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(IUserRepository.self) { UserRepository() }
  }

  private func configureUseCases(_ injector: Injector) {
    // Analytics use cases
    injector.map(CreateVisitUseCase.self) { CreateVisitUseCase() }
    injector.map(GetActiveVisitIDUseCase.self) { GetActiveVisitIDUseCase() }
    injector.map(StopVisitUseCase.self) { StopVisitUseCase() }
    injector.map(UpdateTagsForActiveVisitUseCase.self) { UpdateTagsForActiveVisitUseCase() }
    injector.map(UploadGeopositionsForActiveVisitUseCase.self) { UploadGeopositionsForActiveVisitUseCase() }
    injector.map(UploadGeopositionsForVisitUseCase.self) { UploadGeopositionsForVisitUseCase() }
    injector.map(UploadPositionsForVisitUseCase.self) { UploadPositionsForVisitUseCase() }
    injector.map(UploadScanEventForActiveVisitUseCase.self) { UploadScanEventForActiveVisitUseCase() }
    injector.map(UploadTriggerEventForActiveVisitUseCase.self) { UploadTriggerEventForActiveVisitUseCase() }
    injector.map(UploadZoneSummaryForActiveVisitUseCase.self) { .init() }
    injector.map(UploadVisitScoreForActiveVisitUseCase.self) { UploadVisitScoreForActiveVisitUseCase() }
    injector.map(ValidateVisitScoreUseCase.self) { ValidateVisitScoreUseCase() }

    // Authentication use cases
    injector.map(GetApiKeyUseCase.self) { GetApiKeyUseCase() }
    injector.map(GetAuthSettingsUseCase.self) { GetAuthSettingsUseCase() }
    injector.map(GetAuthTokenUseCase.self) { GetAuthTokenUseCase() }
    injector.map(GetRefreskTokenUseCase.self) { GetRefreskTokenUseCase() }
    injector.map(LoginUseCase.self) { LoginUseCase() }
    injector.map(RefreshUseCase.self) { RefreshUseCase() }
    injector.map(SetApiKeyUseCase.self) { SetApiKeyUseCase() }
    injector.map(SetAuthSettingsUseCase.self) { SetAuthSettingsUseCase() }

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
    injector.map(CreateVPSPathfindersUseCase.self) { .init() }
    injector.map(FetchMapFenceUseCase.self) { FetchMapFenceUseCase() }
    injector.map(FetchMapZonesUseCase.self) { FetchMapZonesUseCase() }
    injector.map(FetchNavGraphUseCase.self) { FetchNavGraphUseCase() }
    injector.map(FetchShelfGroupsUseCase.self) { FetchShelfGroupsUseCase() }
    injector.map(GetActiveCoordinateConverterUseCase.self) { GetActiveCoordinateConverterUseCase() }
    injector.map(GetActiveFloorUseCase.self) { GetActiveFloorUseCase() }
    injector.map(GetActiveMapFenceUseCase.self) { GetActiveMapFenceUseCase() }
    injector.map(GetActiveMapZonesUseCase.self) { GetActiveMapZonesUseCase() }
    injector.map(GetActiveNavGraphUseCase.self) { GetActiveNavGraphUseCase() }
    injector.map(GetActivePathfinderUseCase.self) { .init() }
    injector.map(GetActiveShelfGroupsUseCase.self) { GetActiveShelfGroupsUseCase() }
    injector.map(GetCachedFloorsUseCase.self) { GetCachedFloorsUseCase() }
    injector.map(GetMapZonesUseCase.self) { GetMapZonesUseCase() }
    injector.map(SetActiveFloorUseCase.self) { SetActiveFloorUseCase() }
    injector.map(SetFloorsUseCase.self) { SetFloorsUseCase() }

    // Generic use cases
    injector.map(StopTT2UseCase.self) { StopTT2UseCase() }

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

    // Status use cases
    injector.map(GetCurrentCompassHeadingUseCase.self) { GetCurrentCompassHeadingUseCase() }
    injector.map(GetCurrentGPSLocationUseCase.self) { GetCurrentGPSLocationUseCase() }
    injector.map(GetCurrentLeaseExpiredUseCase.self) { .init() }
    injector.map(GetCurrentLeasePolicyUseCase.self) { GetCurrentLeasePolicyUseCase() }
    injector.map(GetCurrentVPSPositionUseCase.self) { GetCurrentVPSPositionUseCase() }
    injector.map(GetCurrentTT2SettingsUseCase.self) { GetCurrentTT2SettingsUseCase() }
    injector.map(GetIsVPSRunningUseCase.self) { GetIsVPSRunningUseCase() }
    injector.map(GetIsReferenceAngleCertainUseCase.self) { .init() }
    injector.map(SetCompassHeadingUseCase.self) { SetCompassHeadingUseCase() }
    injector.map(SetGPSPositionUseCase.self) { SetGPSPositionUseCase() }
    injector.map(SetLeaseExpiredUseCase.self) { .init() }
    injector.map(SetLeasePolicyUseCase.self) { SetLeasePolicyUseCase() }
    injector.map(SetVPSPositionUseCase.self) { SetVPSPositionUseCase() }
    injector.map(SetIsVPSRunningUseCase.self) { SetIsVPSRunningUseCase() }
    injector.map(SetIsReferenceAngleCertainUseCase.self) { .init() }
    injector.map(SetTT2SettingsUseCase.self) { SetTT2SettingsUseCase() }
    injector.map(SubscribeToCompassHeadingUpdatesUseCase.self) { SubscribeToCompassHeadingUpdatesUseCase() }
    injector.map(SubscribeToGPSUpdatesUseCase.self) { SubscribeToGPSUpdatesUseCase() }
    injector.map(SubscribeToVPSUpdatesUseCase.self) { SubscribeToVPSUpdatesUseCase() }
    injector.map(SubscribeToIsVPSRunningUseCase.self) { SubscribeToIsVPSRunningUseCase() }
    injector.map(SubscribeToIsReferenceAngleCertainUseCase.self) { .init() }
    injector.map(ResetStatusRepositoryUseCase.self) { .init() }

    // Store use cases
    injector.map(FetchStoreUseCase.self) { FetchStoreUseCase() }
    injector.map(FetchSwapLocationsUseCase.self) { FetchSwapLocationsUseCase() }
    injector.map(GetActiveStoreUseCase.self) { GetActiveStoreUseCase() }
    injector.map(GetCachedStoreUseCase.self) { GetCachedStoreUseCase() }
    injector.map(GetCachedSwapLocationsUseCase.self) { GetCachedSwapLocationsUseCase() }
    injector.map(GetZonesTreeUseCase.self) { GetZonesTreeUseCase() }
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
    injector.map(Navigation.self) { [weak self] in
      let inject = Navigation()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(Persistence.self) { Persistence() }
    injector.map(Position.self) { Position() }
    injector.map(VPSPositionManager.self) { [weak self] in
      let inject = VPSPositionManager()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(PositionUploadWorker.self) { PositionUploadWorker() }
    injector.map(RecordingManager.self) { RecordingManager() }
    injector.map(TT2AnalyticsManager.self) { [weak self] in
      let inject = TT2AnalyticsManager()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(TT2EventManager.self) { TT2EventManager() }
    injector.map(TT2ZoneManager.self) { TT2ZoneManager()}
    injector.map(IUserManager.self) { UserManager() }
    injector.map(VSMLModelManager.self) { [weak self] in
      let inject = VSMLModelManager()
      self?.disposables.append(inject)
      return inject
    }
    injector.map(VSTT2FloorManager.self) { VSTT2FloorManager() }
    injector.map(ZoneEventDetector.self) { ZoneEventDetector() }
    injector.map(ILeaseManager.self) { LeaseManager() }
  }

  private func configureHelpers(_ injector: Injector) {
    injector.map(Logger.self) { Logger(verbosity: .debug) }
  }

  func deconfigure(_ injector: Injector) {
    disposables.reversed().forEach { $0.dispose() }
    disposables.removeAll()

    // Services
    injector.unmap(DeleteUserService.self)
    injector.unmap(GetUserService.self)
    injector.unmap(MessagesService.self)
    injector.unmap(OrdersService.self)
    injector.unmap(PutUserService.self)
    injector.unmap(ShelfGroupService.self)
    injector.unmap(StoresListService.self)
    injector.unmap(SwapLocationsService.self)
    injector.unmap(TriggerEventsService.self)
    injector.unmap(UploadStepEventsService.self)
    injector.unmap(UploadSyncEventsService.self)

    // Repositories
    injector.unmap(IAnalyticsRepository.self)
    injector.unmap(IApiKeyRepository.self)
    injector.unmap(IAuthRepository.self)
    injector.unmap(IClientRepository.self)
    injector.unmap(IFloorRepository.self)
    injector.unmap(IItemsRepository.self)
    injector.unmap(IJWTTokenRepository.self)
    injector.unmap(IMLRepository.self)
    injector.unmap(IStatusRepository.self)
    injector.unmap(IStoreRepository.self)
    injector.unmap(IUserRepository.self)

    // Analytics use cases
    injector.unmap(CreateVisitUseCase.self)
    injector.unmap(GetActiveVisitIDUseCase.self)
    injector.unmap(StopVisitUseCase.self)
    injector.unmap(UpdateTagsForActiveVisitUseCase.self)
    injector.unmap(UploadGeopositionsForActiveVisitUseCase.self)
    injector.unmap(UploadGeopositionsForVisitUseCase.self)
    injector.unmap(UploadPositionsForVisitUseCase.self)
    injector.unmap(UploadScanEventForActiveVisitUseCase.self)
    injector.unmap(UploadTriggerEventForActiveVisitUseCase.self)
    injector.unmap(UploadZoneSummaryForActiveVisitUseCase.self)

    injector.unmap(UploadVisitScoreForActiveVisitUseCase.self)
    injector.unmap(ValidateVisitScoreUseCase.self)

    // Authentication use cases
    injector.unmap(GetApiKeyUseCase.self)
    injector.unmap(GetAuthSettingsUseCase.self)
    injector.unmap(GetAuthTokenUseCase.self)
    injector.unmap(GetRefreskTokenUseCase.self)
    injector.unmap(LoginUseCase.self)
    injector.unmap(RefreshUseCase.self)
    injector.unmap(SetApiKeyUseCase.self)
    injector.unmap(SetAuthSettingsUseCase.self)

    // Barcode use case
    injector.unmap(GetPositionByBarcodeUseCase.self)

    // Client use cases
    injector.unmap(FetchClientsUseCase.self)
    injector.unmap(GetActiveClientUseCase.self)
    injector.unmap(GetCachedClientsUseCase.self)
    injector.unmap(SetActiveClientUseCase.self)

    // Event use cases
    injector.unmap(DecideWhichTriggerEventToDisplayUseCase.self)

    // Floor use cases
    injector.unmap(CreateVPSPathfindersUseCase.self)
    injector.unmap(FetchMapFenceUseCase.self)
    injector.unmap(FetchMapZonesUseCase.self)
    injector.unmap(FetchNavGraphUseCase.self)
    injector.unmap(FetchShelfGroupsUseCase.self)
    injector.unmap(GetActiveCoordinateConverterUseCase.self)
    injector.unmap(GetActiveFloorUseCase.self)
    injector.unmap(GetActiveMapFenceUseCase.self)
    injector.unmap(GetActiveMapZonesUseCase.self)
    injector.unmap(GetActiveNavGraphUseCase.self)
    injector.unmap(GetActivePathfinderUseCase.self)
    injector.unmap(GetActiveShelfGroupsUseCase.self)
    injector.unmap(GetCachedFloorsUseCase.self)
    injector.unmap(GetMapZonesUseCase.self)
    injector.unmap(SetActiveFloorUseCase.self)
    injector.unmap(SetFloorsUseCase.self)

    // Generic use cases
    injector.unmap(StopTT2UseCase.self)

    // ML use cases
    injector.unmap(CompileModelUseCase.self)
    injector.unmap(FetchMLInterfaceVersionsUseCase.self)
    injector.unmap(GetMLCatalogUseCase.self)
    injector.unmap(GetMLModelUseCase.self)
    injector.unmap(GetMLVersionUseCase.self)
    injector.unmap(GetNLModelUseCase.self)
    injector.unmap(GetNLVersionUseCase.self)
    injector.unmap(GetVPSMLModelParamsUseCase.self)
    injector.unmap(GetVPSNLModelParamsUseCase.self)
    injector.unmap(LoadMLVersionUseCase.self)
    injector.unmap(LoadNLVersionUseCase.self)
    injector.unmap(SetMLVersionUseCase.self)
    injector.unmap(SetNLVersionUseCase.self)

    // Status use cases
    injector.unmap(GetCurrentCompassHeadingUseCase.self)
    injector.unmap(GetCurrentGPSLocationUseCase.self)
    injector.unmap(GetCurrentLeaseExpiredUseCase.self)
    injector.unmap(GetCurrentLeasePolicyUseCase.self)
    injector.unmap(GetCurrentVPSPositionUseCase.self)
    injector.unmap(GetCurrentTT2SettingsUseCase.self)
    injector.unmap(GetIsVPSRunningUseCase.self)
    injector.unmap(SetCompassHeadingUseCase.self)
    injector.unmap(SetGPSPositionUseCase.self)
    injector.unmap(SetLeaseExpiredUseCase.self)
    injector.unmap(SetLeasePolicyUseCase.self)
    injector.unmap(SetVPSPositionUseCase.self)
    injector.unmap(SetIsVPSRunningUseCase.self)
    injector.unmap(SetTT2SettingsUseCase.self)
    injector.unmap(SubscribeToCompassHeadingUpdatesUseCase.self)
    injector.unmap(SubscribeToGPSUpdatesUseCase.self)
    injector.unmap(SubscribeToVPSUpdatesUseCase.self)
    injector.unmap(SubscribeToIsVPSRunningUseCase.self)

    // Store use cases
    injector.unmap(FetchStoreUseCase.self)
    injector.unmap(FetchSwapLocationsUseCase.self)
    injector.unmap(GetActiveStoreUseCase.self)
    injector.unmap(GetCachedStoreUseCase.self)
    injector.unmap(GetCachedSwapLocationsUseCase.self)
    injector.unmap(GetZonesTreeUseCase.self)
    injector.unmap(SetActiveStoreUseCase.self)

    // User use cases
    injector.unmap(GetUserProfileUseCase.self)
    injector.unmap(SetUserProfileUseCase.self)

    // Managers
    injector.unmap(AWSS3UploadManager.self)
    injector.unmap(CoordinateEventDetector.self)
    injector.unmap(DownloadManager.self)
    injector.unmap(EventDetector.self)
    injector.unmap(MapZoneParser.self)
    injector.unmap(Navigation.self)
    injector.unmap(Persistence.self)
    injector.unmap(Position.self)
    injector.unmap(VPSPositionManager.self)
    injector.unmap(PositionUploadWorker.self)
    injector.unmap(RecordingManager.self)
    injector.unmap(TT2AnalyticsManager.self)
    injector.unmap(TT2EventManager.self)
    injector.unmap(TT2ZoneManager.self)
    injector.unmap(IUserManager.self)
    injector.unmap(VSMLModelManager.self)
    injector.unmap(VSTT2FloorManager.self)
    injector.unmap(ZoneEventDetector.self)
    injector.unmap(ILeaseManager.self)
  }
}
