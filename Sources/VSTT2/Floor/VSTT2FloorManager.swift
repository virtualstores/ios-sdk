//
// VSTT2FloorManager
// VSTT2
//
// Created by Hripsime on 2022-02-22
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine
import CoreGraphics
import VSPositionKit

public class VSTT2FloorManager: VSTT2Floor {
    @Inject var downloadManager: DownloadManager
    @Inject var mapFenceDataService: MapFenceDataService
    @Inject var swapLocationsService: SwapLocationsService

    private var floorPicker: FloorPicker?

    public var activeFloor: RtlsOptions?
    public var floors: [RtlsOptions] = []
    public var pathFinder: VSPathFinder?
    public var zones: Data?
    public var messages: [Message]?
    public var mapZones: [Int : [MapZone]] = [:]
    public var mapZonePoints: [Int : [MapZonePoint]] = [:]
    public var offsetZones: Data?
    public var navgraph: Data?

    public var switchFloorPublisher: CurrentValueSubject<(rtlsOptions: RtlsOptions, point: CGPoint)?, Never> = .init(nil)
    
    public var startCode: PositionedCode? {
        self.activeFloor?.scanLocations?.first(where: { $0.type == .start })
    }
    
    public var stopCode: PositionedCode? {
        self.activeFloor?.scanLocations?.first(where: { $0.type == .stop })
    }

    private var cancellable = Set<AnyCancellable>()
    private let dispatchGroup = DispatchGroup()

    private var mapFence: MapFence?

    init() {}

    func setup(swapLocations: [SwapLocation]) {
        if let activeFloor = activeFloor {
            self.floorPicker = FloorPicker(rtlsOptionId: activeFloor.id, swapLocations: swapLocations)

            self.floorPicker?.switchFloorPublisher
                .sink(receiveValue: { [weak self] (data) in
                    guard let rtlsOptions = self?.floors.first(where: { $0.id == data?.rtlsOptionsId }), let point = data?.point else { return }
                    self?.switchFloorPublisher.send((rtlsOptions: rtlsOptions, point: point))
                }).store(in: &cancellable)
        }
    }

    public func setActiveFloor(with rtlsOptions: RtlsOptions) {
        self.setActiveFloor(with: rtlsOptions) { (mapFence, zones, points) in }
    }
    
    public func setActiveFloor(with floorLevel: Int) { }
    
    public func updateFloorInAnalyticsController() { }
    
    func setupFloors(with rtlsOptions: [RtlsOptions]) {
        self.floors = rtlsOptions
    }
    
    internal func setActiveFloor(with rtlsOptions: RtlsOptions, completion: @escaping ((mapFence: MapFence?, zones: [Int: [MapZone]]?, points: [Int: [MapZonePoint]]?)) -> ()) {
        guard floors.contains(where: { $0.id == rtlsOptions.id }) else { return }
                
        self.activeFloor = rtlsOptions
        
        getFloorData { (mapFence, zones, points) in
            completion((mapFence: mapFence, zones: zones, points: points))
        }
    }
  
    func onNewPostion(location: CGPoint) {
        self.floorPicker?.onNewPosition(location: location)
    }

    func onNewFloor(floor: Int) {
        floorPicker?.changeFloorTo = floor
    }
    
    deinit {
        cancellable.removeAll()
    }
}

private extension VSTT2FloorManager {
    private func getFloorData(completion: @escaping ((mapFence: MapFence?, zones: [Int: [MapZone]]?, points: [Int: [MapZonePoint]]?)) -> ()) {
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
        floors.forEach { rtls in
          guard let mapZonesUrl = rtls.mapZonesUrl, let url = URL(string: mapZonesUrl) else { return }
          dispatchGroup.enter()

          downloadManager.loadData(from: url) { result in
              switch result {
              case .success(let data):
                  let mapData = MapZoneParser.getMapZonesData(fromJsonData: data)

                  self.mapZones[rtls.floorLevel] = mapData.mapzones
                  self.mapZonePoints[rtls.floorLevel] = mapData.mapPoints
                  self.dispatchGroup.leave()
              case .failure(let error):
                  Logger.init().log(message: error.localizedDescription)
              }
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

class GraphLoader {
  func getGraph(fromFile: String, pixelHeight: Double) -> TT2NavGraph {
    return GraphDeserializer.deserialize(fromJsonFile: fromFile, pixelHeight: pixelHeight)
  }

  func getGraph(fromData: Data, pixelHeight: Double) -> TT2NavGraph {
    return GraphDeserializer.deserialize(fromJsonData: fromData, pixelHeight: pixelHeight)
  }
}

private typealias VertexMap = Dictionary<String, TT2NavGraph.Vertex>
private typealias JsonData = Dictionary<String, AnyObject>
private typealias NeighborData = Dictionary<String, Int>
private typealias NeighborDataKotlin = Dictionary<String, Int32>

class GraphDeserializer: NSObject {
  static func deserialize(fromJsonFile: String, pixelHeight: Double) -> TT2NavGraph {
    let filePath = Bundle.main.path(forResource: fromJsonFile, ofType: "json")!
    let data = try! Data(referencing: NSData(contentsOfFile: filePath))
    return deserialize(fromJsonData: data, pixelHeight: pixelHeight)
  }

  static func deserialize(fromJsonData data: Data, pixelHeight: Double) -> TT2NavGraph {
    let json = try! JSONSerialization.jsonObject(with: data,
                                                 options: JSONSerialization.ReadingOptions.allowFragments) as! JsonData
    let numvertices = json["num_vertices"] as! Int
    let spacing = json["spacing"] as! Double
    var output = VertexMap()
    let polygons = json["vertices"] as! [JsonData]
    for object in polygons{
      let id = object["id"] as! String
      let x = object["x"] as! CGFloat
      let y = object["y"] as! CGFloat
      let cost = object["cost"] as! Int
      let neighborCost = object["neighbors"] as! NeighborData

      var neighborCostKotlin: NeighborDataKotlin = [:]
      neighborCost.forEach { (key, value) in
        neighborCostKotlin[key] = Int32(value)
      }

      let vertice = TT2NavGraph.Vertex(id: id, x: Float(x), y: Float(y), cost: Int32(cost), neighborCosts: neighborCostKotlin)
      //let vertice = NavGraph.Vertex(id: id, x: Float(x), y: Float(CGFloat(pixelHeight) - y), cost: Int32(cost), neighborCosts: neighborCost)
      output.updateValue(vertice, forKey: id)
    }

    return TT2NavGraph(spacing: spacing, numVertices: Int32(numvertices), vertices: output)
    //return NavGraph(spacing: Int32(spacing), numVertices: Int32(numvertices), vertices: output)
  }
}
