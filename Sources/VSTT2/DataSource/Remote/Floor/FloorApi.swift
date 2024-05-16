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
  func getMapFence(url: String, completion: @escaping (Result<MapFence, Error>) -> ())
  func getMapZones(url: URL, completion: @escaping (Result<ZoneData, Error>) -> ())
  func getNavGraph(url: URL, completion: @escaping (Result<Data, Error>) -> ())
  func getSwapLocations(completion: @escaping (Result<[SwapLocation], Error>) -> ())
}

class FloorApi {
  @Inject var downloadManager: DownloadManager
  @Inject var mapFenceService: MapFenceDataService
  @Inject var swapLocationsService: SwapLocationsService
  private var cancellable = Set<AnyCancellable>()
}

extension FloorApi: IFloorApi {
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

  func getSwapLocations(completion: @escaping (Result<[SwapLocation], Error>) -> ()) {

  }
}
