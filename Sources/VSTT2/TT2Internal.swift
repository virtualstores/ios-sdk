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
    @Inject var user: UserSettings
    @Inject var recording: Recording
    @Inject var awsS3UploadManager: AWSS3UploadManager
    
    /// Services for getting the api data
    @Inject var clientListService : ClientsListService
    @Inject var storesListService: StoresListService
    @Inject var swapLocationsService: SwapLocationsService
    @Inject var ordersService: OrdersService
    @Inject var itemPositionService: ItemPositionService
    @Inject var shelfGroupService: ShelfGroupService
    
    var accuracyUploader: AccuracyUploader?
    var deviceOrientationUploader: DeviceOrientationUploader?
    var mapController: IMapController?
    
    private let config: EnvironmentConfig
    private var cancellable = Set<AnyCancellable>()
    
    private var offset: Double
    
    var internalClients: [Client] = []
    var internalStores: [Store] = []
    var shelfGroups: [Int64: [ShelfGroup]] = [:]
    
    public init(config: EnvironmentConfig) {
        self.config = config
        offset = 0.0
        bindPublishers()
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
        let parameters = StoresListParameters(clientId: clientId, config: config)
        
        storesListService
            .call(with: parameters)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    completion(error)
                    Logger(verbosity: .critical).log(message: "No available store")
                }
            }, receiveValue: { (data) in
                self.internalStores = data.stores
                completion(nil)
            }).store(in: &cancellable)
    }
    
    func getShelfGroups(for storeId: Int64, activeFloor: RtlsOptions?, completion: @escaping ( [ShelfGroup]) -> ()) {
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
        navigation.positionKitManager.positionPublisher
            .compactMap{ $0 }
            .sink { error in
                Logger.init().log(message: "PositionKitError noData")
            } receiveValue: { [weak self] positionBundle in
                self?.floorManager.onNewPostion(location: positionBundle.position)
                self?.mapController?.updateUserLocation(newLocation: positionBundle.position, std: positionBundle.std)
                self?.analytics.onNewPositionBundle(point: positionBundle.position)
            }
            .store(in: &cancellable)
        
        navigation.positionKitManager.changedFloorPublisher
            .compactMap { $0 }
            .sink { [weak self] (data) in
                self?.floorManager.onNewFloor(floor: data)
            }
            .store(in: &cancellable)
        
        navigation.positionKitManager.directionPublisher
            .compactMap { $0 }
            .sink { error in
                Logger.init().log(message: "DirectionPublisher noData")
            } receiveValue: { direction in
                let heading = (self.vpsToMapboxAngle(angle: direction.angle + self.offset)).remainder(dividingBy: 360.0)
                self.mapController?.updateUserDirection(newDirection: heading)
            }
            .store(in: &cancellable)
        
        navigation.positionKitManager.realWorldOffsetPublisher
            .compactMap { $0 }
            .sink { error in
                Logger.init().log(message: "RealWorldOffsetPublisher noData")
            } receiveValue: { direction in
                self.offset = direction.angle
            }
            .store(in: &cancellable)
        
        navigation.accuracyPublisher
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] (preScanLocation, scanLocation, offset) in
                guard let id = self?.analytics.visitId else { return }
                self?.accuracyUploader?.upload(id: String(id), articleId: "", preScanLocation: preScanLocation, offset: offset, scanLocation: scanLocation, errorHandler: { (error) in
                    Logger(verbosity: .info).log(message: "AccuracyUploaderError: \(error.localizedDescription)")
                })
            })
            .store(in: &cancellable)

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

        
        navigation.positionKitManager.recordingPublisher
            .compactMap { $0 }
            .sink(receiveValue: { (identifier ,data) in
                self.createAWSData(identifier: identifier, data: data)
            })
            .store(in: &cancellable)

        recording.sendDataPublisher
            .sink { (_) in
                self.sendAWSData()
            }.store(in: &cancellable)
    }

    func sendAWSData() {
        guard let stringDate = recordingStringDate, let time = recordingStringTime else {
//            if recording.recorded {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.sendAWSData() }
//            }
            return
        }

        let folderName: String
        if let user = self.user.getLastUser() {
            let deviceName = user.deviceName ?? UIDevice.current.name
            if let name = user.name ?? user.userId, let route = user.route {
              folderName = "\(stringDate)/\(name)_\(deviceName)/ios/\(route)/\(time)/"
            } else if let name = user.name ?? user.userId {
              folderName = "\(stringDate)/\(name)_\(deviceName)/ios/undefinedRoute/\(time)/"
            } else {
              folderName = "\(stringDate)/undefined/ios/undefinedRoute/\(time)/"
            }
        } else {
            folderName = "\(stringDate)/undefined/ios/undefinedRoute/\(time)/"
        }
        awsS3UploadManager.sendCollectedDataToS3(folderName: folderName)
        recordingStringDate = nil
        recordingStringTime = nil
    }

    var recordingStringDate: String?
    var recordingStringTime: String?
    func createAWSData(identifier: String, data: String) {
        guard let store = position.store else { return }
        let date = Date()
        let uploadTimeFormatter = DateFormatter()
        let uploadDayFormatter = DateFormatter()
        uploadTimeFormatter.dateFormat = "HHmmss"
        uploadDayFormatter.dateFormat = "yyMMdd"
        let stringDate = uploadDayFormatter.string(from: date)
        let time = uploadTimeFormatter.string(from: date)
        awsS3UploadManager.prepareDataToSend(identifier: identifier, data: data, date: date)
        let csvData = createCSVData(date: stringDate, time: time, serverUrl: config.centralServerConnection.serverAddress ?? "", clientId: String(store.clientId), storeid: String(store.id))
        let fileName = "keywords\(time).csv"
        awsS3UploadManager.addAditionalData(identifier: identifier, fileName: fileName, data: csvData)
        recordingStringDate = stringDate
        recordingStringTime = time
    }
    
    func createCSVData(date: String, time: String, serverUrl: String, clientId: String, storeid: String) -> String {
        var csvData = "day,name,device,route,time,gender,age,comments,serverUrl,clientID,storeID,activity\n"
        guard let user = user.getLastUser() else { return csvData + "\(date),,,ios,,\(time),,,,\(serverUrl),\(clientId),\(storeid),,\n" }
        let name = user.name ?? user.userId ?? ""
        let route = user.route ?? ""
        let gender = user.gender ?? ""
        let age = user.age ?? ""
        let comments = user.comments ?? ""
        let activity = user.activity ?? ""
        csvData = csvData + "\(date),\(name),ios,\(route),\(time),\(gender),\(age),\(comments),\(serverUrl),\(clientId),\(storeid),\(activity)\n"
        return csvData
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
    
    
    /// move this methode in manager where needed
    /// now it's here just for testing the API
    func postOrders(storeId: Int64, orderIds: [String], device: DeviceInformation) {
        let parameters = OrdersParameters(storeId: storeId, orderIds: orderIds, deviceInformation: device, config: config)
        
        ordersService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: {_ in
                
            }).store(in: &cancellable)
    }
    
    func getItemPosition(storeId: Int64, itemId: String) {
        let parameters = ItemPositionParameters(storeId: storeId, barcode: itemId, config: config)
        
        itemPositionService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { data in
                print(data)
            }).store(in: &cancellable)
    }
    
    deinit {
        cancellable.removeAll()
    }
}
