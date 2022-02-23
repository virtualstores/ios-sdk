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
    public var mapFence: MapFence?
    public var zones: Data?
    public var messages: [Message]?
    public var mapZones: [MapZone] = []
    public var mapZonePoints: [MapZonePoint] = []
    public var offsetZones: Data?
    public var navgraph: Data?
    
    public var mapDataPublisher: CurrentValueSubject<(zones: [MapZone]?, points: [MapZonePoint]?), Never> = .init((zones: nil, points: nil))
    public var floorDataLoaded: CurrentValueSubject<MapFence?, Never> = .init(nil)

    public var startCodes: PositionedCode? {
        self.activeFloor?.scanLocations?.first(where: { $0.type == .start })
    }
    
    public var stopCodes: PositionedCode? {
        self.activeFloor?.scanLocations?.first(where: { $0.type == .stop })
    }

    private var cancellable = Set<AnyCancellable>()

    init() {}
    
    public func setActiveFloor(with rtlsOptions: RtlsOptions) {
        guard floors.contains(where: { $0.id == rtlsOptions.id }) else { return }
                
        self.activeFloor = rtlsOptions
        
        getFloorData()
    }
    
    public func setActiveFloor(with floorLevel: Int) { }
    
    public func updateFloorInAnalyticsController() { }
    
    func setupFloors(with rtlsOptions: [RtlsOptions]) {
        self.floors = rtlsOptions
    }
}

private extension VSTT2FloorManager {
    private func getFloorData() {
        getMapFenceData()
        getMapZones()
        getNavGraph()
    }
    
    private func getMapFenceData() {
        guard let url = self.activeFloor?.mapFenceUrl  else { return }
        
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
                self?.floorDataLoaded.send(data)
            }).store(in: &cancellable)
    }
    
    private func getMapZones() {
        guard let mapZonesUrl = self.activeFloor?.mapZonesUrl, let url = URL(string: mapZonesUrl) else { return }
        
        downloadManager.loadData(from: url) { result in
            switch result {
            case .success(let data):
                let mapData = MapZoneParser.getMapZonesData(fromJsonData: data)
                
                self.mapZones = mapData.mapzones
                self.mapZonePoints = mapData.mapPoints
                self.mapDataPublisher.send((zones: self.mapZones, points: self.mapZonePoints))
                print(self.mapZones)
            case .failure(let error):
                Logger.init().log(message: error.localizedDescription)
            }
        }
    }
    
    private func getNavGraph() {
        guard let navGraphUrl = self.activeFloor?.navGraphUrl, let url = URL(string: navGraphUrl) else { return }
        
        downloadManager.loadData(from: url) { result in
            switch result {
            case .success(let data):
                self.navgraph = data
            case .failure(let error):
                Logger.init().log(message: error.localizedDescription)
            }
        }
    }
}
