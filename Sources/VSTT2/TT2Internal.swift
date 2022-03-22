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
    
    /// Services for getting the api data
    @Inject var clientListService : ClientsListService
    @Inject var storesListService: StoresListService
    @Inject var swapLocationsService: SwapLocationsService
    @Inject var ordersService: OrdersService
    @Inject var itemPositionService: ItemPositionService
    @Inject var shelfGroupService: ShelfGroupService

    var accuracyUploader: AccuracyUploader?
    var mapController: IMapController?
    var map: Map?

    private let config: EnvironmentConfig
    private var clientsCancellablle = Set<AnyCancellable>()
    private var cancellable = Set<AnyCancellable>()
    private var positionBundleCancellable: AnyCancellable?
    private var changedFloorCancellable: AnyCancellable?
    private var directionCancellable: AnyCancellable?
    private var realWorldOffsetCancellable: AnyCancellable?
    private var accuracyCancellable: AnyCancellable?

    private var offset: Double

    var internalClients: [Client] = []
    var internalStores: [Store] = []

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
            }.store(in: &clientsCancellablle)
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
        let shelfGroupParameters = ShelfGroupParameters(storeId: storeId, config: config)
        
        shelfGroupService
            .call(with: shelfGroupParameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { (shelfData) in
                let shelfGroups = shelfData.map({ ShelfGroupDto.toShelfGroup($0) })
                completion(shelfGroups)
                if let activeFloor = activeFloor {
                    self.map = Map(id: storeId, mapURL: activeFloor.mapBoxUrl ?? "", storeId: storeId, railScale: 0, pixelOffsetX: Int(activeFloor.startOffsetX), pixelOffsetY: Int(activeFloor.startOffsetY), pixelWidth: Int(activeFloor.rtlsOptionsWidth()), pixelHeight: Int(activeFloor.rtlsOptionsHeight()))
                }
            }).store(in: &cancellable)
    }
    
    
    private func bindPublishers() {
        positionBundleCancellable = navigation.positionKitManager.positionPublisher
            .compactMap{ $0 }
            .sink { error in
                Logger.init().log(message: "PositionKitError noData")
            } receiveValue: { [weak self] positionBundle in
                self?.floorManager.onNewPostion(location: positionBundle.position)
                self?.mapController?.updateUserLocation(newLocation: positionBundle.position, std: positionBundle.std)
                self?.analytics.onNewPositionBundle(point: positionBundle.position)
            }

        changedFloorCancellable = navigation.positionKitManager.changedFloorPublisher
            .compactMap { $0 }
            .sink { [weak self] (data) in
                self?.floorManager.onNewFloor(floor: data)
            }
        
        directionCancellable = navigation.positionKitManager.directionPublisher
            .compactMap { $0 }
            .sink { error in
                Logger.init().log(message: "DirectionPublisher noData")
            } receiveValue: { direction in
                let heading = (self.vpsToMapboxAngle(angle: direction.angle + self.offset)).remainder(dividingBy: 360.0)
                self.mapController?.updateUserDirection(newDirection: heading)
            }

        realWorldOffsetCancellable = navigation.positionKitManager.realWorldOffsetPublisher
            .compactMap { $0 }
            .sink { error in
                Logger.init().log(message: "RealWorldOffsetPublisher noData")
            } receiveValue: { direction in
                self.offset = direction.angle
            }

        accuracyCancellable = navigation.accuracyPublisher
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] (preScanLocation, scanLocation, offset) in
                guard let id = self?.analytics.visitId else { return }
                self?.accuracyUploader?.upload(id: String(id), articleId: "", preScanLocation: preScanLocation, offset: offset, scanLocation: scanLocation, errorHandler: { (error) in
                    Logger(verbosity: .info).log(message: "AccuracyUploaderError: \(error.localizedDescription)")
                })
            })
    }

    private func vpsToMapboxAngle(angle: Double) -> Double{
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
}
