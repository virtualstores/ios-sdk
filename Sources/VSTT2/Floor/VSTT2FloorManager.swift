//
// VSTT2FloorManager
// VSTT2
//
// Created by Hripsime on 2022-02-22
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine
import VSPositionKit

public class VSTT2FloorManager: VSTT2Floor {
    @Inject var downloadManager: DownloadManager
    @Inject var mapFenceDataService: MapFenceDataService
    
    public var activeFloor: RtlsOptions?
    public var floors: [RtlsOptions] = []
    public var pathFinder: VSPathFinder?
    public var zones: Data?
    public var messages: [Message]?
    public var mapZones: [MapZone] = []
    public var mapZonePoints: [MapZonePoint] = []
    public var offsetZones: Data?
    public var navgraph: Data?
    
    public var startCodes: PositionedCode? {
        self.activeFloor?.scanLocations?.first(where: { $0.type == .start })
    }
    
    public var stopCodes: PositionedCode? {
        self.activeFloor?.scanLocations?.first(where: { $0.type == .stop })
    }

    private var cancellable = Set<AnyCancellable>()
    private let dispatchGroup = DispatchGroup()

    private var mapFence: MapFence?

    init() {}
    
    public func setActiveFloor(with rtlsOptions: RtlsOptions) {
        self.setActiveFloor(with: rtlsOptions) { (mapFence, zones, points) in }
    }
    
    public func setActiveFloor(with floorLevel: Int) { }
    
    public func updateFloorInAnalyticsController() { }
    
    func setupFloors(with rtlsOptions: [RtlsOptions]) {
        self.floors = rtlsOptions
    }
    
    internal func setActiveFloor(with rtlsOptions: RtlsOptions, completion: @escaping ((mapFence: MapFence?, zones: [MapZone]?, points: [MapZonePoint]?)) -> ()) {
        guard floors.contains(where: { $0.id == rtlsOptions.id }) else { return }
                
        self.activeFloor = rtlsOptions
        
        getFloorData { (mapFence, zones, points) in
            completion((mapFence: mapFence, zones: zones, points: points))
        }
    }
}

private extension VSTT2FloorManager {
    private func getFloorData(completion: @escaping ((mapFence: MapFence?, zones: [MapZone]?, points: [MapZonePoint]?)) -> ()) {
        getMapFenceData()
        getMapZones()
        getNavGraph()
        
        dispatchGroup.notify(queue: .main) {
            if let mapFance = self.mapFence {
                completion((mapFence: mapFance, zones: self.mapZones, points: self.mapZonePoints))
            }
        }
    }
    
    private func getMapFenceData() {
        guard let url = self.activeFloor?.mapFenceUrl  else { return }
        dispatchGroup.enter()
        let parameters = MapFenceDataParameters(url: url)
        mapFenceDataService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { [weak self] (data) in
                self?.mapFence = data
                self?.dispatchGroup.leave()
            }).store(in: &cancellable)
    }
    
    private func getMapZones() {
        guard let mapZonesUrl = self.activeFloor?.mapZonesUrl, let url = URL(string: mapZonesUrl) else { return }
        dispatchGroup.enter()

        downloadManager.loadData(from: url) { result in
            switch result {
            case .success(let data):
                let mapData = MapZoneParser.getMapZonesData(fromJsonData: data)
                
                self.mapZones = mapData.mapzones
                self.mapZonePoints = mapData.mapPoints
                self.dispatchGroup.leave()
            case .failure(let error):
                Logger.init().log(message: error.localizedDescription)
            }
        }
    }
    
    private func getNavGraph() {
        guard let navGraphUrl = self.activeFloor?.navGraphUrl, let url = URL(string: navGraphUrl) else { return }
        dispatchGroup.enter()

        downloadManager.loadData(from: url) { result in
            switch result {
            case .success(let data):
                self.navgraph = data
                self.dispatchGroup.leave()
            case .failure(let error):
                Logger.init().log(message: error.localizedDescription)
            }
        }
    }
}
