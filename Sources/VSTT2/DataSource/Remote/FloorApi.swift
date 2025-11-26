//
//  FloorApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import Combine
import VSFoundation

protocol IFloorApi {
  func getMapFence(url: String) -> AnyPublisher<MapFence, Error>
  func getMapZones(url: URL) -> AnyPublisher<ZoneData, Error>
  func getNavGraph(url: URL) -> AnyPublisher<Data, Error>
  func getShelfGroups(rtlsOptionsId: Int64) -> AnyPublisher<[ShelfGroup], Error>
}

class FloorApi {
  private let tag = "FloorApi"
  private let downloadManager = DownloadManager()
  private let mapFenceService = MapFenceDataService(with: NetworkManager())
  private let shelfGroupService = ShelfGroupService(with: NetworkManager())
}

extension FloorApi: IFloorApi {
  func getMapFence(url: String) -> AnyPublisher<MapFence, Error> {
    mapFenceService.call(with: .init(url: url))
  }

  func getMapZones(url: URL) -> AnyPublisher<ZoneData, Error> {
    downloadManager.loadData(from: url)
      .tryMap {
        guard let data = MapZoneParser.getMapZonesData(fromJsonData: $0) else { throw TT2Error.missingData }
        return data
      }
      .eraseToAnyPublisher()
  }

  func getNavGraph(url: URL) -> AnyPublisher<Data, Error> {
    downloadManager.loadData(from: url)
  }

  func getShelfGroups(rtlsOptionsId: Int64) -> AnyPublisher<[ShelfGroup], Error> {
    shelfGroupService
      .call(with: .init(rtlsOptionsId: rtlsOptionsId))
      .map { ShelfGroupDto.add(floorLevelId: rtlsOptionsId, $0).map(ShelfGroupDto.toShelfGroup) }
      .eraseToAnyPublisher()
  }
}
