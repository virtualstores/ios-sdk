//
// TT2Internal
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine
import UIKit

internal class TT2Internal {
    /// Managers for helping VSTT2 to work with separate small modules
    @Inject var navigation: Navigation
    @Inject var analytics: TT2AnalyticsManager
    @Inject var floorManager: VSTT2FloorManager
    @Inject var position: Position
    @Inject var user: UserController
    @Inject var recording: RecordingManager
    @Inject var awsS3UploadManager: AWSS3UploadManager
    @Inject var mlModelManager: VSMLModelManager
    
    /// Services for getting the api data
    @Inject var clientListService : ClientsListService
    @Inject var swapLocationsService: SwapLocationsService
    @Inject var ordersService: OrdersService
    @Inject var itemPositionService: ItemPositionService
    @Inject var shelfGroupService: ShelfGroupService

    /// Usecases
    @Inject var fetchStoreUseCase: FetchStoreUseCase
    @Inject var getCachedStoreUseCase: GetCachedStoreUseCase
    @Inject var getActiveStoreUseCase: GetActiveStoreUseCase
    @Inject var setActiveStoreUseCase: SetActiveStoreUseCase
    
    var deviceOrientationUploader: DeviceOrientationUploader?
    var mapController: IMapController?
    var wifiController: IWiFiController?
    
    private let config: EnvironmentConfig
    private var cancellable = Set<AnyCancellable>()
    
    private var offset: Double
    
    var internalClients: [Client] = []
    var internalStores: [Store] { getCachedStoreUseCase.invoke(filterOnlyActive: false) }
    var internalStoresActive: [Store] { getCachedStoreUseCase.invoke() }
    var activeStore: Store { getActiveStoreUseCase.invoke() }
    var activeClient: Client?
    var shelfGroups: [Int64: [ShelfGroup]] = [:]
    var automaticActivationOfUserMark: Bool = true
    var automaticSensorRecording: Bool { activeStore.hasSensorRecordingActive }
    
    public init(config: EnvironmentConfig) {
        self.config = config
        offset = 0.0
        bindPublishers()
    }

    deinit {
        cancellable.removeAll()
    }
    
    func createMapData(rtlsOptions: RtlsOptions, mapFence: MapFence, coordinateConverter: ICoordinateConverter?) -> MapData? {
        guard let converter = coordinateConverter else { return nil }
        
        let mapData = MapData(rtlsOptions: rtlsOptions, converter: converter)
        
        return mapData
    }
    
    
    func getClients(completion: @escaping (Error?) -> Void) {
        let parameters = ClientsListParameters(config: config)
        
        clientListService
            .call(with: parameters)
            .sink { (result) in
                switch result {
                case .finished: break
                case .failure(let error): completion(error)
                }
            } receiveValue: { (data) in
                self.internalClients = data.clients
                completion(nil)
            }.store(in: &cancellable)
    }
    
    func getStores(with clientId: Int64, completion: @escaping (Error?) -> ()) {
        fetchStoreUseCase.invoke(clientId: clientId, completion: completion)
    }

    func setActiveStore(storeId: Int64) {
        setActiveStoreUseCase.invoke(storeId: storeId)
    }
    
    func getShelfGroups(for storeId: Int64, activeFloor: RtlsOptions?, completion: @escaping ([ShelfGroup]) -> ()) {
        guard let activeFloor = activeFloor else { return }
        let group = DispatchGroup()
        floorManager.floors.forEach { (rtlsOption) in
            group.enter()
            let shelfGroupParameters = ShelfGroupParameters(storeId: storeId, rtlsOptionsId: rtlsOption.id, config: config)
            shelfGroupService
                .call(with: shelfGroupParameters)
                .sink(receiveCompletion: { (completion) in
                    switch completion {
                    case .finished: break
                    case .failure(let error): print(error)
                    }
                }, receiveValue: { (shelfData) in
                    let shelfGroups = ShelfGroupDto.add(floorLevelId: rtlsOption.id, shelfData).map({ ShelfGroupDto.toShelfGroup($0) })
                    self.shelfGroups[rtlsOption.id] = shelfGroups
                    group.leave()
                }).store(in: &cancellable)
        }

        group.notify(queue: .main) {
            guard let shelfGroups = self.shelfGroups[activeFloor.id] else { return }
            completion(shelfGroups)
        }
    }
    
    
    private func bindPublishers() {
        navigation.isActivePublisher
          .sink { [weak self] (isActive) in
              if isActive {
                  if self?.automaticActivationOfUserMark ?? true {
                      self?.mapController?.start()
                  }
                  if self?.automaticSensorRecording ?? false {
                      self?.recording.start()
                  }
              } else {
                  self?.mapController?.stop()
              }
          }.store(in: &cancellable)

        navigation.positionKitManager.positionPublisher
            .compactMap{ $0 }
            .sink { error in
                Logger.init().log(message: "PositionKitError noData")
            } receiveValue: { [weak self] positionBundle in
                self?.floorManager.onNewPostion(location: positionBundle.position)
                self?.mapController?.updateUserLocation(newLocation: positionBundle.position, std: positionBundle.std)
                self?.analytics.onNewPositionBundle(point: positionBundle.position)
            }.store(in: &cancellable)
        
        navigation.positionKitManager.changedFloorPublisher
            .compactMap { $0 }
            .sink { [weak self] (data) in
                self?.floorManager.onNewFloor(floor: data)
            }.store(in: &cancellable)
        
        navigation.positionKitManager.directionPublisher
            .compactMap { $0 }
            .sink { error in
                Logger.init().log(message: "DirectionPublisher noData")
            } receiveValue: { direction in
                let heading = (self.vpsToMapboxAngle(angle: direction.angle + self.offset)).remainder(dividingBy: 360.0)
                self.mapController?.updateUserDirection(newDirection: heading)
            }.store(in: &cancellable)
        
        navigation.positionKitManager.realWorldOffsetPublisher
            .compactMap { $0 }
            .sink { error in
                Logger.init().log(message: "RealWorldOffsetPublisher noData")
            } receiveValue: { direction in
                self.offset = direction.angle
            }.store(in: &cancellable)

        navigation.positionKitManager.deviceOrientationPublisher
            .compactMap { $0 }
            .sink { (error) in
              Logger(verbosity: .info).log(message: "DeviceOrientationError: \(error)")
            } receiveValue: { [weak self] (orientation) in
                guard
                    let id = self?.analytics.visitId,
                    let position = self?.navigation.positionKitManager.positionPublisher.value?.position,
                    let direction = self?.navigation.positionKitManager.directionPublisher.value?.angle
                else { return }
                self?.deviceOrientationUploader?.upload(id: "", visitId: id, deviceOrientation: orientation.rawValue, currentLocation: position, direction: direction, errorHandler: { (error) in
                    Logger(verbosity: .info).log(message: "DeviceOrientationUploaderError: \(error.localizedDescription)")
                })
            }.store(in: &cancellable)

        navigation.positionKitManager.recordingPublisherPartial
            .compactMap { $0 }
            //.sink(receiveValue: { [weak self] (identifier, data, sessionId) in
            .sink(receiveValue: { [weak self] (identifier, data) in
                self?.awsS3UploadManager.prepareDataToSend(identifier: identifier, data: data, folderName: self?.generateAWSFolderPath(visitId: self?.analytics.visitId), date: Date())
                self?.awsS3UploadManager.sendCollectedDataToS3()
            }).store(in: &cancellable)
        navigation.positionKitManager.recordingPublisherEnd
            .compactMap { $0 }
            //.sink(receiveValue: { [weak self] (identifier, data, sessionId) in
            .sink(receiveValue: { [weak self] (identifier, data) in
                self?.awsS3UploadManager.prepareDataToSend(identifier: identifier, data: data, folderName: self?.generateAWSFolderPath(visitId: self?.analytics.visitId, additionalData: true), date: Date())
                self?.awsS3UploadManager.sendCollectedDataToS3()
            }).store(in: &cancellable)

        navigation.positionKitManager.rescueModePublisher
          .compactMap { $0 }
          .sink { [weak self] (_) in
            self?.analytics.accuracyUploader?.numberOfRescueModes += 1
          }.store(in: &cancellable)

        navigation.positionKitManager.mlDataPublisher
            .compactMap { $0 }
            .sink { [weak self] (mlData) in
              guard let id = self?.user.userId else { return }
              self?.user.updateUserML(id, mlData: mlData, completion: { (_) in })
            }.store(in: &cancellable)
        navigation.positionKitManager.onMlCalibrationPublisher
            .compactMap { $0 }
            .sink { [weak self] (mlUser) in
              self?.analytics.updateVisitWithMLTags(mlUser: mlUser)
            }.store(in: &cancellable)

        navigation.positionKitManager.stepEventDataPublisher
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] in self?.analytics.stepEventUploader?.events.append($0) })
            .store(in: &cancellable)
        
        navigation.accuracyPublisher
            .compactMap { $0 }
            .sink { [weak self] (data) in
                self?.analytics.accuracyUploader?.upload(syncEvent: data.event, isFloorSwap: data.isFloorSwap)
            }.store(in: &cancellable)

        recording.sendDataPublisher
            .sink { [weak self] (_) in
                self?.awsS3UploadManager.sendCollectedDataToS3(objects: self?.awsS3UploadManager.getAllRecordedObjects ?? [])
            }.store(in: &cancellable)

        analytics.zoneManager.onEnterPublisher
            .compactMap { $0 }
            .sink { [weak self] (zone) in
                self?.mapController?.zone.onEnterPublisher.send(zone)
            }.store(in: &cancellable)

        analytics.zoneManager.onExitPublisher
            .compactMap { $0 }
            .sink { [weak self] (zone) in
                self?.mapController?.zone.onExitPublisher.send(zone)
            }.store(in: &cancellable)
    }

    func generateAWSFolderPath(visitId: Int64?, additionalData: Bool = false) -> String? {
        var serverAddress = config.centralServerConnection.serverAddress?.trimmingCharacters(in: CharacterSet(charactersIn: "htps:/"))
        if serverAddress?.hasSuffix("/api/v1") ?? false || serverAddress?.hasSuffix("/api/v2") ?? false {
          serverAddress?.removeLast(7)
        }
        var dataServerAddress = analytics.config?.centralServerConnection.serverAddress?.trimmingCharacters(in: CharacterSet(charactersIn: "htps:/"))
        if dataServerAddress?.hasSuffix("/api/v1") ?? false || dataServerAddress?.hasSuffix("/api/v2") ?? false {
          dataServerAddress?.removeLast(7)
        }

        guard let serverAddress = serverAddress, let id = visitId else { return nil }
        let folderName: String = "\(serverAddress)/\(id)/"
        if additionalData, let dataServerAddress = dataServerAddress, let tags = createTT2Tags(serverAddress: serverAddress, dataServerAddress: dataServerAddress, visitId: id) {
            awsS3UploadManager.prepareDataToSend(identifier: "tags.json", data: tags, folderName: folderName, date: Date())
        }
        return folderName
    }

    func createTT2Tags(serverAddress: String, dataServerAddress: String, visitId: Int64) -> String? {
        guard
          let tt2SdkVersion = analytics.tt2Tags["tt2SdkVersion"],
          let tt2VpsVersion = analytics.tt2Tags["tt2VpsVersion"],
          let tt2DeviceManufacturer = analytics.tt2Tags["tt2DeviceManufacturer"],
          let tt2DeviceModel = analytics.tt2Tags["tt2DeviceModel"],
          let tt2DeviceOs = analytics.tt2Tags["tt2DeviceOs"],
          let tt2DeviceOsVersion = analytics.tt2Tags["tt2DeviceOsVersion"],
          let tt2MLActive = analytics.tt2Tags["tt2MLActive"],
          let tt2SdkVpsSettingUseML = analytics.tt2Tags["tt2SdkVpsSettingUseML"],
          let tt2SdkVpsSettingUseCoefficientOptimizer = analytics.tt2Tags["tt2SdkVpsSettingUseCoefficientOptimizer"],
          let tt2SdkVpsSettingUseDriftCompensator = analytics.tt2Tags["tt2SdkVpsSettingUseDriftCompensator"],
          let tt2RtlsOptionsId = floorManager.activeFloor?.id,
          let tt2ClientId = activeClient?.clientId
        else { return nil }
        return "{\"tags\":{\"tt2SdkVersion\":\"\(tt2SdkVersion)\",\"tt2VpsVersion\":\"\(tt2VpsVersion)\",\"tt2DeviceManufacturer\":\"\(tt2DeviceManufacturer)\",\"tt2DeviceModel\":\"\(tt2DeviceModel)\",\"tt2DeviceOs\":\"\(tt2DeviceOs)\",\"tt2DeviceOsVersion\":\"\(tt2DeviceOsVersion)\",\"tt2MLActive\":\"\(tt2MLActive)\",\"tt2SdkVpsSettingUseML\":\"\(tt2SdkVpsSettingUseML)\",\"tt2SdkVpsSettingUseCoefficientOptimizer\":\"\(tt2SdkVpsSettingUseCoefficientOptimizer)\",\"tt2SdkVpsSettingUseDriftCompensator\":\"\(tt2SdkVpsSettingUseDriftCompensator)\",\"tt2CentralServerURL\":\"\(serverAddress)\",\"tt2DataServerURL\":\"\(dataServerAddress)\",\"tt2RtlsOptionsId\":\"\(tt2RtlsOptionsId)\",\"tt2StoreId\":\"\(activeStore.id)\",\"tt2VisitId\":\"\(visitId)\",\"tt2ClientId\":\"\(tt2ClientId)\"}}"
    }
    
    private func vpsToMapboxAngle(angle: Double) -> Double {
        90.0 - angle
    }
    
    func getSwapLocations(for storeId: Int64, completion: @escaping (Result<[SwapLocation], Error>) -> Void) {
        let swapLocationsParameters = SwapLocationsParameters(storeId: storeId, config: config)
        
        swapLocationsService
            .call(with: swapLocationsParameters)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                    completion(.failure(error))
                }
            }, receiveValue: { (swapLocations) in
                completion(.success(swapLocations))
            }).store(in: &cancellable)
    }
}
