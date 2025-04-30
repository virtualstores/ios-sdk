//
//  FloorApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import Combine
import VSFoundation

class MockFloorApi {
  private let downloadManager = DownloadManager()
  private let mapFenceService = MapFenceDataService(with: NetworkManager())
  private let shelfGroupService = ShelfGroupService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension MockFloorApi: IFloorApi {
  func getMapFence(url: String, completion: @escaping (Result<MapFence, Error>) -> ()) {
    mapFenceService
      .call(with: MapFenceDataParameters(url: url))
      .sink(receiveCompletion: { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      }, receiveValue: { (data) in
        completion(.success(data))
      }).store(in: &cancellable)
  }

  func getMapZones(url: URL, completion: @escaping (Result<ZoneData, Error>) -> ()) {
    downloadManager.loadData(from: url) { result in
      switch result {
      case .success(let data):
        guard
          let mapData = MapZoneParser.getMapZonesData(fromJsonData: data)
        else { completion(.failure(VSTT2Error.missingData)); return }
        completion(.success(mapData))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getNavGraph(url: URL, completion: @escaping (Result<Data, Error>) -> ()) {
    downloadManager.loadData(from: url) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getShelfGroups(rtlsOptionsId: Int64, completion: @escaping (Result<[ShelfGroup], Error>) -> ()) {
    shelfGroupService
      .call(with: ShelfGroupParameters(rtlsOptionsId: rtlsOptionsId))
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      } receiveValue: { (data) in
        completion(.success(ShelfGroupDto.add(floorLevelId: rtlsOptionsId, data).map({ ShelfGroupDto.toShelfGroup($0) })))
      }.store(in: &cancellable)
  }
}
