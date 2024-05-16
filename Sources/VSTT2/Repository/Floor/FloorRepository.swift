//
//  FloorRepository.swift
//
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import VSFoundation

protocol IFloorRepository {
  var activeFloor: RtlsOptions { get }
  var activeMapFence: MapFence? { get }
  var activeMapZones: ZoneData? { get }
  var activeNavGraph: Data? { get }

  func getRtlsOptions() -> [RtlsOptions]
  func set(activeFloor: RtlsOptions)
  func set(cachedFloors: [RtlsOptions])
  func fetchMapFence(completion: @escaping (Error?) -> ())
  func fetchMapZones(completion: @escaping (Error?) -> ())
  func fetchNavGraph(completion: @escaping (Error?) -> ())
}

class FloorRepository {
  private let api: IFloorApi = FloorApi()
  private var _activeFloor: RtlsOptions?
  private var floors: [RtlsOptions] = []
  private var mapFences: [Int64: MapFence] = [:]
  private var mapZonesData: [Int64: ZoneData] = [:]
  private var navgraphs: [Int64: Data] = [:]
}

extension FloorRepository: IFloorRepository {
  var activeFloor: RtlsOptions {
    guard let floor = _activeFloor else { fatalError("Floor not set") }
    return floor
  }

  var activeMapFence: MapFence? { mapFences[activeFloor.id] }
  var activeMapZones: ZoneData? { mapZonesData[activeFloor.id] }
  var activeNavGraph: Data? { navgraphs[activeFloor.id] }

  func getRtlsOptions() -> [RtlsOptions] { floors }

  func set(activeFloor: RtlsOptions) {
    _activeFloor = activeFloor
  }
  
  func set(cachedFloors: [RtlsOptions]) {
    floors = cachedFloors
  }
  
  func fetchMapFence(completion: @escaping (Error?) -> ()) {
    guard !floors.isEmpty else { completion(VSTT2Error.missingData); return }
    let group = DispatchGroup()
    var error: Error?
    floors.forEach { (rtls) in
      guard let url = rtls.mapFenceUrl else { return }
      group.enter()
      api.getMapFence(url: url) { [weak self] (result) in
        switch result {
        case .success(let mapFence): self?.mapFences[rtls.id] = mapFence
        case .failure(let err): error = err
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion(error)
    }
  }

  func fetchMapZones(completion: @escaping (Error?) -> ()) {
    guard !floors.isEmpty else { completion(VSTT2Error.missingData); return }
    let group = DispatchGroup()
    var error: Error?
    floors.forEach { (floor) in
      guard
        let mapZonesUrl = floor.mapZonesUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let url = URL(string: mapZonesUrl)
      else { return }
      group.enter()
      api.getMapZones(url: url) { [weak self] (result) in
        switch result {
        case .success(let data): self?.mapZonesData[floor.id] = data
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
    guard !floors.isEmpty else { completion(VSTT2Error.missingData); return }
    let group = DispatchGroup()
    var error: Error?
    floors.forEach { (floor) in
      guard 
        let navGraphUrl = floor.navGraphUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let url = URL(string: navGraphUrl)
      else { return }
      group.enter()
      api.getNavGraph(url: url) { [weak self] (result) in
        switch result {
        case .success(let data): 
          self?.navgraphs[floor.id] = data
        case .failure(let err): error = err
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion(error)
    }
  }
}
