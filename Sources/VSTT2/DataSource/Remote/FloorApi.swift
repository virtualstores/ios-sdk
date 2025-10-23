//
//  FloorApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import Combine
import VSFoundation

protocol IFloorApi: Disposable {
  func getMapFence(url: String, completion: @escaping (Result<MapFence, Error>) -> ())
  func getMapZones(url: URL, completion: @escaping (Result<ZoneData, Error>) -> ())
  func getNavGraph(url: URL, completion: @escaping (Result<Data, Error>) -> ())
  func getShelfGroups(rtlsOptionsId: Int64, completion: @escaping (Result<[ShelfGroup], Error>) -> ())
}

class FloorApi {
  private let tag = "FloorApi"
  private let downloadManager = DownloadManager()
  private let mapFenceService = MapFenceDataService(with: NetworkManager())
  private let shelfGroupService = ShelfGroupService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension FloorApi: IFloorApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellable.removeAll()
  }
  
  func getMapFence(url: String, completion: @escaping (Result<MapFence, Error>) -> ()) {
    mapFenceService
      .call(with: MapFenceDataParameters(url: url))
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellable)
  }

  func getMapZones(url: URL, completion: @escaping (Result<ZoneData, Error>) -> ()) {
    downloadManager.loadData(from: url)
      .tryMap {
        guard let data = MapZoneParser.getMapZonesData(fromJsonData: $0) else { throw TT2Error.missingData }
        return data
      }
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellable)
  }

  func getNavGraph(url: URL, completion: @escaping (Result<Data, Error>) -> ()) {
    downloadManager.loadData(from: url)
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellable)
  }

  func getShelfGroups(rtlsOptionsId: Int64, completion: @escaping (Result<[ShelfGroup], Error>) -> ()) {
    shelfGroupService
      .call(with: ShelfGroupParameters(rtlsOptionsId: rtlsOptionsId))
      .map { ShelfGroupDto.add(floorLevelId: rtlsOptionsId, $0).map(ShelfGroupDto.toShelfGroup) }
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellable)
  }
}
