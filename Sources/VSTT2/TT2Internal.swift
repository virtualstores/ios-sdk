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
    @Inject var config: EnvironmentConfig
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
    
    public init() {
        offset = 0.0
        bindPublishers()
    }

    deinit {
        cancellable.removeAll()
    }
    
    func createMapData(rtlsOptions: RtlsOptions, mapFence: MapFence, coordinateConverter: ICoordinateConverter?) -> MapData? {
        guard let converter = coordinateConverter else { return nil }
        return MapData(rtlsOptions: rtlsOptions, converter: converter)
    }
    
    
    func getClients(completion: @escaping (Error?) -> Void) {
        clientListService
            .call(with: ClientsListParameters())
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
            let shelfGroupParameters = ShelfGroupParameters(storeId: storeId, rtlsOptionsId: rtlsOption.id)
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
                      //self?.recording.start()
                  }
              } else {
                  self?.mapController?.stop()
              }
          }.store(in: &cancellable)

        navigation.positionKitManager.recordingPublisher
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] (identifier, data, sessionId, lastFile) in
                self?.awsS3UploadManager.prepareDataToSend(identifier: identifier, data: data, folderName: self?.generateAWSFolderPath(visitId: self?.analytics.visitId, additionalData: lastFile), date: Date())
                self?.awsS3UploadManager.sendCollectedDataToS3()
            }).store(in: &cancellable)

        navigation.positionKitManager.outputSignalPublisher
            .compactMap { $0 }
            .sink { [self] (signal) in
              switch signal {
              case .position(position: let position):
                navigation.currentPosition = position.position
                floorManager.onNewPostion(location: position.position)
                mapController?.updateUserLocation(newLocation: position.position, std: position.std)
                analytics.onNewPositionBundle(position: position)
              case .ux(position: let position): break
                //mapController?.updateUserLocation(newLocation: position.position, std: position.std)
              case .ml(position: let position):
                if navigation.positionKitManager.isRecording {
                  if let id = floorManager.activeFloor?.id {
                    analytics.addMLPositions(id: id, position: position)
                  }
                }
              case .rotation(heading: let heading):
                let heading = (vpsToMapboxAngle(angle: heading + offset)).remainder(dividingBy: 360.0)
                self.mapController?.updateUserDirection(newDirection: heading)
              }
            }.store(in: &cancellable)
        
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
        guard
            let serverAddress = config.centralServerConnection.serverAddress?.trimServerAddress,
            let dataServerAddress = config.analyticsServerConnection.serverAddress?.trimServerAddress,
            let id = visitId
        else { return nil }
        let folderName: String = "\(serverAddress)/\(dataServerAddress)/\(id)/"
        if additionalData, let tags = createTT2Tags(serverAddress: serverAddress, dataServerAddress: dataServerAddress, visitId: id) {
            awsS3UploadManager.prepareDataToSend(identifier: "tags.json", data: tags, folderName: folderName, date: Date())
        }
        return folderName
    }

    func createTT2Tags(serverAddress: String, dataServerAddress: String, visitId: Int64) -> String? {
        analytics.tt2Tags["tt2CentralServerURL"] = serverAddress
        analytics.tt2Tags["tt2DataServerURL"] = dataServerAddress
        analytics.tt2Tags["tt2RtlsOptionsId"] = floorManager.activeFloor?.id.description
        analytics.tt2Tags["tt2StoreId"] = activeStore.id.description
        analytics.tt2Tags["tt2VisitId"] = visitId.description
        analytics.tt2Tags["tt2ClientId"] = activeClient?.clientId.description
        let tags = TT2Tags(tags: analytics.tt2Tags)
        guard let data = try? JSONEncoder().encode(tags) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private struct TT2Tags: Codable {
      let tags: [String:String]
    }

    private func vpsToMapboxAngle(angle: Double) -> Double {
        90.0 - angle
    }
    
    func getSwapLocations(for storeId: Int64, completion: @escaping (Result<[SwapLocation], Error>) -> Void) {
        swapLocationsService
            .call(with: SwapLocationsParameters(storeId: storeId))
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

private extension String {
  var trimServerAddress: String {
    var modified = self
    if hasPrefix("http://") { modified.removeFirst(7) }
    if hasPrefix("https://") { modified.removeFirst(8) }
    if hasSuffix("/api/v1") || hasSuffix("/api/v2") { modified.removeLast(7) }
    return modified
  }
}
