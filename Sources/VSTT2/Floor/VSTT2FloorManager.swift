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

class VSTT2FloorManager {
  @Inject var createConverters: CreateCoordinateConvertersUseCase
  @Inject var fetchMapFence: FetchMapFenceUseCase
  @Inject var fetchMapZones: FetchMapZonesUseCase
  @Inject var fetchNavGraph: FetchNavGraphUseCase
  @Inject var fetchShelfGroups: FetchShelfGroupsUseCase
  @Inject var getActiveConverter: GetActiveCoordinateConverterUseCase
  @Inject var getActiveFloor: GetActiveFloorUseCase
  @Inject var getActiveMapFence: GetActiveMapFenceUseCase
  @Inject var getActiveMapZones: GetActiveMapZonesUseCase
  @Inject var getActiveNavGraph: GetActiveNavGraphUseCase
  @Inject var getActiveShelfGroups: GetActiveShelfGroupsUseCase
  @Inject var getFloors: GetCachedFloorsUseCase
  @Inject var getMapZones: GetMapZonesUseCase
  @Inject var setActiveFloor: SetActiveFloorUseCase
  @Inject var setFloors: SetFloorsUseCase

  var switchFloorPublisher: CurrentValueSubject<(rtlsOptions: RtlsOptions, point: CGPoint?)?, Never> = .init(nil)

  private var cancellable = Set<AnyCancellable>()
  private let dispatchGroup = DispatchGroup()

  private(set) var swapLocations: [SwapLocation] = []
  private lazy var floorPicker: FloorPicker = {
    FloorPicker(rtlsOptionId: activeFloor.id, swapLocations: swapLocations)
  }()

  deinit {
    cancellable.removeAll()
  }
}

private extension VSTT2FloorManager {
  func getFloorData(completion: @escaping ((mapFence: MapFence?, zoneData: [Int64: ZoneData]?)) -> ()) {
    getMapFenceData()
    getMapZonesData()
    getNavGraph()
    getShelfGroups()

    dispatchGroup.notify(queue: .main) {
      DispatchQueue.main.async {
        self.createConverters.invoke()
        if let mapFence = self.getActiveMapFence.invoke() {
          completion((mapFence: mapFence, zoneData: self.zoneData))
        }
      }
    }
  }

  func getMapFenceData() {
    dispatchGroup.enter()
    fetchMapFence.invoke { (error) in
      if error == nil {
        DispatchQueue.main.async {
          self.dispatchGroup.leave()
        }
      }
    }
  }

  func getMapZonesData() {
    dispatchGroup.enter()
    fetchMapZones.invoke { (error) in
      if error == nil {
        DispatchQueue.main.async {
          self.dispatchGroup.leave()
        }
      }
    }
  }

  func getNavGraph() {
    dispatchGroup.enter()
    fetchNavGraph.invoke { (error) in
      if error == nil {
        DispatchQueue.main.async {
          self.dispatchGroup.leave()
        }
      }
    }
  }

  func getShelfGroups() {
    dispatchGroup.enter()
    fetchShelfGroups.invoke() { (error) in
      if error == nil {
        DispatchQueue.main.async {
          self.dispatchGroup.leave()
        }
      }
    }
  }
}

extension VSTT2FloorManager {
  var zoneData: [Int64: ZoneData] { getMapZones.invoke() }
  var startCode: PositionedCode? { activeFloor.scanLocations?.first(where: { $0.type == .start }) }
  var stopCode: PositionedCode? { activeFloor.scanLocations?.first(where: { $0.type == .stop }) ?? startCode }

  func setup(swapLocations: [SwapLocation]) {
    self.swapLocations = swapLocations
    floorPicker.switchFloorPublisher
      .compactMap { $0 }
      .sink(receiveValue: { [weak self] (data) in
        guard let rtlsOptions = self?.floors.first(where: { $0.id == data.rtlsOptionsId }) else { return }
        self?.switchFloorPublisher.send((rtlsOptions: rtlsOptions, point: data.point))
      }).store(in: &cancellable)
  }

  func setupFloors(with rtlsOptions: [RtlsOptions]) {
    setFloors.invoke(cachedFloors: rtlsOptions)
  }

  func setActiveFloor(with rtlsOptions: RtlsOptions, completion: @escaping ((mapFence: MapFence?, zoneData: [Int64: ZoneData]?)) -> ()) {
    guard floors.contains(where: { $0.id == rtlsOptions.id }) else { return }

    setActiveFloor.invoke(rtlsOptionsId: rtlsOptions.id)

    getFloorData { (mapFence, zoneData) in
      completion((mapFence: mapFence, zoneData: zoneData))
    }
  }

  func onNewPostion(location: CGPoint) {
    floorPicker.onNewPosition(location: location)
  }

  func onNewFloor(floor: Int) {
    floorPicker.changeOfFloor(floor: floor)
  }
}

extension VSTT2FloorManager: VSTT2Floor {
  public var activeFloor: RtlsOptions { getActiveFloor.invoke() }
  public var floors: [RtlsOptions] { getFloors.invoke() }

  public func setActiveFloor(with rtlsOptions: RtlsOptions) {
    setActiveFloor(with: rtlsOptions) { (mapFence, zoneData) in }
  }

  public func setActiveFloor(with floorLevel: Int) { }
}

class GraphLoader {
  static func getGraph(fromFile: String, pixelHeight: Double) -> TT2NavGraph {
    GraphDeserializer.deserialize(fromJsonFile: fromFile, pixelHeight: pixelHeight)
  }

  static func getGraph(fromData: Data, pixelHeight: Double) -> TT2NavGraph {
    GraphDeserializer.deserialize(fromJsonData: fromData, pixelHeight: pixelHeight)
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
    polygons.forEach { (object) in
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
