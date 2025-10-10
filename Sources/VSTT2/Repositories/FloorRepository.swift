//
//  FloorRepository.swift
//
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import VSFoundation
import VSPositionKit

protocol IFloorRepository: Disposable {
  var activeConverter: ICoordinateConverter? { get throws }
  var activeFloor: RtlsOptions { get throws }
  var activeMapFence: MapFence? { get throws }
  var activeMapZones: ZoneData? { get throws }
  var activeNavGraph: Data? { get throws }
  var activeVpsPathfinder: VPSPathfinderAdapter? { get throws }
  var activeShelfGroups: [ShelfGroup]? { get throws }

  func createVPSPathfinders()
  func fetchMapFence(completion: @escaping (Error?) -> ())
  func fetchMapZones(completion: @escaping (Error?) -> ())
  func fetchNavGraph(completion: @escaping (Error?) -> ())
  func fetchShelfGroups(completion: @escaping (Error?) -> ())
  func getRtlsOptions() -> [RtlsOptions]
  func getMapZones() -> [Int64: ZoneData]
  func set(activeFloor: RtlsOptions)
  func set(cachedFloors: [RtlsOptions])
}

class FloorRepository {
  @Inject var config: EnvironmentConfig
  private let tag = "FloorRepository"
  private let api: IFloorApi = FloorApi()
  private var _activeFloor: RtlsOptions?
  private var converters: [Int64: ICoordinateConverter] = [:]
  private var floors: [RtlsOptions] = []
  private var mapFences: [Int64: MapFence] = [:]
  private var mapZonesData: [Int64: ZoneData] = [:]
  private var navgraphs: [Int64: Data] = [:]
  private var vpsPathfinders: [Int64: VPSPathfinderAdapter] = [:]
  private var shelfGroups: [Int64: [ShelfGroup]] = [:]

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }

  private func createConverters() {
    mapFences.forEach { (key, value) in
      converters[key] = BaseCoordinateConverter(
        heightInPixels: value.properties.height,
        widthInPixels: value.properties.width,
        pixelPerMeter: (try? activeFloor.pixelsPerMeter) ?? 50.0,
        pixelPerLatitude: 1000.0
      )
    }
  }
}

extension FloorRepository: IFloorRepository {
  var activeConverter: ICoordinateConverter? { get throws { converters[try activeFloor.id] } }
  var activeFloor: RtlsOptions {
    get throws {
      guard let floor = _activeFloor else { throw TT2Error.noFloorSet }
      return floor
    }
  }
  var activeMapFence: MapFence? { get throws { mapFences[try activeFloor.id] } }
  var activeMapZones: ZoneData? { get throws { mapZonesData[try activeFloor.id] } }
  var activeNavGraph: Data? { get throws { navgraphs[try activeFloor.id] } }
  var activeVpsPathfinder: VPSPathfinderAdapter? { get throws { vpsPathfinders[try activeFloor.id] } }
  var activeShelfGroups: [ShelfGroup]? { get throws { shelfGroups[try activeFloor.id] } }

  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    api.dispose()
    _activeFloor = nil
    converters = [:]
    floors = []
    mapFences = [:]
    mapZonesData = [:]
    navgraphs = [:]
    vpsPathfinders.forEach { $0.value.dispose() }
    vpsPathfinders = [:]
    shelfGroups = [:]
  }

  func createVPSPathfinders() {
    floors.forEach { (rtls) in
      guard
        let converter = converters[rtls.id],
        let navData = navgraphs[rtls.id],
        let stopCode = rtls.scanLocations?.filter({ $0.isRouteLocation }).first(where: { $0.type == .stop })
      else { return }

      let height = converter.convertFromMetersToPixels(input: rtls.heightInMeters)
      let navGraph = GraphDeserializer.deserialize(fromJsonData: navData, pixelHeight: height)
      let startCode = rtls.scanLocations?.filter({ $0.isRouteLocation }).first(where: { $0.type == .start })
      let convertedAndFlippedStart = startCode?.point.fromMeterToPixel(converter: converter).flipY(converter: converter)
      let convertedAndFlippedStop = stopCode.point.fromMeterToPixel(converter: converter).flipY(converter: converter)
      vpsPathfinders[rtls.id] = VPSPathfinderAdapter(
        converter: converter,
        height: rtls.heightInMeters,
        width: rtls.widthInMeters,
        pixelsPerMeter: Float(rtls.pixelsPerMeter),
        navGraph: navGraph,
        startPosition: convertedAndFlippedStart,
        stopPosition: convertedAndFlippedStop
      )
    }
  }

  func fetchMapFence(completion: @escaping (Error?) -> ()) {
    guard !floors.isEmpty else { completion(TT2Error.missingData); return }
    let group = DispatchGroup()
    var error: Error?
    floors.forEach { (rtls) in
      guard let url = rtls.mapFenceUrl?.checkUrl(config: config) else { return }
      group.enter()
      api.getMapFence(url: url) { [weak self] (result) in
        switch result {
        case .success(let mapFence):
          DispatchQueue.main.async {
            self?.mapFences[rtls.id] = mapFence
          }
        case .failure(let err): error = err
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      self.createConverters()
      completion(error)
    }
  }

  func fetchMapZones(completion: @escaping (Error?) -> ()) {
    guard !floors.isEmpty else { completion(TT2Error.missingData); return }
    let group = DispatchGroup()
    var error: Error?
    floors.forEach { (floor) in
      guard
        let mapZonesUrl = floor.mapZonesUrl?.checkUrl(config: config).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let url = URL(string: mapZonesUrl)
      else { return }
      group.enter()
      api.getMapZones(url: url) { [weak self] (result) in
        switch result {
        case .success(let data):
          DispatchQueue.main.async {
            self?.mapZonesData[floor.id] = data
          }
        case .failure(let err): error = err
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion(error)
    }
  }

  func fetchNavGraph(completion: @escaping (Error?) -> ()) {
    guard !floors.isEmpty else { completion(TT2Error.missingData); return }
    let group = DispatchGroup()
    var error: Error?
    floors.forEach { (floor) in
      guard 
        let navGraphUrl = floor.navGraphUrl?.checkUrl(config: config).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let url = URL(string: navGraphUrl)
      else { return }
      group.enter()
      api.getNavGraph(url: url) { [weak self] (result) in
        switch result {
        case .success(let data):
          DispatchQueue.main.async {
            self?.navgraphs[floor.id] = data
          }
        case .failure(let err): error = err
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion(error)
    }
  }

  func fetchShelfGroups(completion: @escaping (Error?) -> ()) {
    guard !floors.isEmpty else { completion(TT2Error.missingData); return }
    let group = DispatchGroup()
    var error: Error?
    floors.forEach { (floor) in
      group.enter()
      api.getShelfGroups(rtlsOptionsId: floor.id) { [weak self] (result) in
        switch result {
        case .success(let shelfGroups):
          if shelfGroups.count > 0 {
            DispatchQueue.main.async {
              self?.shelfGroups[floor.id] = shelfGroups
            }
          }
        case .failure(let err): error = err
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion(error)
    }
  }

  func getRtlsOptions() -> [RtlsOptions] { floors }

  func getMapZones() -> [Int64: ZoneData] { mapZonesData }

  func set(activeFloor: RtlsOptions) {
    _activeFloor = activeFloor
  }

  func set(cachedFloors: [RtlsOptions]) {
    dispose()
    floors = cachedFloors
  }
}

extension String {
  func checkUrl(config: EnvironmentConfig) -> String {
    if config.connection is EnvironmentConfig.Gateway, let baseURL = config.connection.tt2ResourceUrl {
      return replaceBaseurl(with: baseURL)
    }
    return self
  }

  func replaceBaseurl(with baseurl: String) -> String {
    guard
      range(of: "\\b.s3\\b.*\\bamazonaws.com\\b", options: .regularExpression) != nil,
      let path = components(separatedBy: ".amazonaws.com").last
    else { return self }
    return baseurl + path
  }
}
