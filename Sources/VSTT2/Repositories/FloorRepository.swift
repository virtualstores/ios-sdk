//
//  FloorRepository.swift
//
//
//  Created by Théodore Roos on 2024-05-02.
//

import Combine
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
  var activeZoneShelves: [Shelf]? { get throws }

  func createVPSPathfinders()
  func fetchMapFence() -> AnyPublisher<Void, Error>
  func fetchMapZones() -> AnyPublisher<Void, Error>
  func fetchNavGraph() -> AnyPublisher<Void, Error>
  func fetchShelfGroups() -> AnyPublisher<Void, Error>
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
  private var navGraphs: [Int64: Data] = [:]
  private var vpsPathfinders: [Int64: VPSPathfinderAdapter] = [:]
  private var shelfGroups: [Int64: [ShelfGroup]] = [:]
  private var zoneShelves: [Int64: [Shelf]] = [:]

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
  var activeNavGraph: Data? { get throws { navGraphs[try activeFloor.id] } }
  var activeVpsPathfinder: VPSPathfinderAdapter? { get throws { vpsPathfinders[try activeFloor.id] } }
  var activeShelfGroups: [ShelfGroup]? { get throws { shelfGroups[try activeFloor.id] } }
  var activeZoneShelves: [Shelf]? { get throws { zoneShelves[try activeFloor.id] } }

  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    api.dispose()
    _activeFloor = nil
    converters = [:]
    floors = []
    mapFences = [:]
    mapZonesData = [:]
    navGraphs = [:]
    vpsPathfinders.forEach { $0.value.dispose() }
    vpsPathfinders = [:]
    shelfGroups = [:]
  }

  func createVPSPathfinders() {
    floors.forEach { (rtls) in
      guard
        let converter = converters[rtls.id],
        let navData = navGraphs[rtls.id],
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

  func fetchMapFence() -> AnyPublisher<Void, Error> {
    // Build one publisher per valid floor
    let publishers: [AnyPublisher<(id: Int64, data: MapFence), Error>] = floors
      .compactMap { (rtls) in
        guard let url = rtls.mapFenceUrl?.checkUrl(config: config) else { return nil }
        return api.getMapFence(url: url).map { (rtls.id, $0) }.eraseToAnyPublisher()
      }
    guard !publishers.isEmpty else { return .fail(with: TT2Error.missingData) }
    return Publishers.MergeMany(publishers)
      .collect()
      .receive(on: DispatchQueue.main)
      .handleEvents(receiveOutput: { [weak self] in
        $0.forEach { self?.mapFences[$0.id] = $0.data }
        self?.createConverters()
      })
      .map { _ in () } // If requests are succesful return void
      .eraseToAnyPublisher()
  }

  func fetchMapZones() -> AnyPublisher<Void, Error> {
    let publishers: [AnyPublisher<(id: Int64, data: ZoneData), Error>] = floors
      .compactMap { (rtls) in
        guard
          let mapZonesUrl = rtls.mapZonesUrl?.checkUrl(config: config).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: mapZonesUrl)
        else { return nil }
        return api.getMapZones(url: url).map { (rtls.id, $0) }.eraseToAnyPublisher()
      }
    guard !publishers.isEmpty else { return .fail(with: TT2Error.missingData) }
    return Publishers.MergeMany(publishers)
      .collect()
      .receive(on: DispatchQueue.main)
      .handleEvents(receiveOutput: { [weak self] in
        $0.forEach { self?.mapZonesData[$0.id] = $0.data }
      })
      .map { _ in () } // If requests are succesful return void
      .eraseToAnyPublisher()
  }

  func fetchNavGraph() -> AnyPublisher<Void, Error> {
    let publishers: [AnyPublisher<(id: Int64, data: Data), Error>] = floors
      .compactMap { (rtls) in
        guard
          let navGraphUrl = rtls.navGraphUrl?.checkUrl(config: config).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: navGraphUrl)
        else { return nil }
        return api.getNavGraph(url: url).map { (rtls.id, $0) }.eraseToAnyPublisher()
      }
    guard !publishers.isEmpty else { return .fail(with: TT2Error.missingData) }
    return Publishers.MergeMany(publishers)
      .collect()
      .receive(on: DispatchQueue.main)
      .handleEvents(receiveOutput: { [weak self] in
        $0.forEach { self?.navGraphs[$0.id] = $0.data }
      })
      .map { _ in () } // If requests are succesful return void
      .eraseToAnyPublisher()
  }

  func fetchShelfGroups() -> AnyPublisher<Void, Error> {
    let publishers: [AnyPublisher<(id: Int64, data: [ShelfGroup]), Error>] = floors
      .map { (rtls) in
        api.getShelfGroups(rtlsOptionsId: rtls.id).map { (rtls.id, $0) }.eraseToAnyPublisher()
      }
    guard !publishers.isEmpty else { return .fail(with: TT2Error.missingData) }
    return Publishers.MergeMany(publishers)
      .collect()
      .receive(on: DispatchQueue.main)
      .handleEvents(receiveOutput: { [weak self] in
        $0.forEach {
          self?.shelfGroups[$0.id] = $0.data
          self?.zoneShelves[$0.id] = $0.data
            .map { $0.shelves }
            .flatMap { $0 }
            .filter { $0.name?.contains("@zone") ?? false }
        }
      })
      .map { _ in () } // If requests are succesful return void
      .eraseToAnyPublisher()
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
