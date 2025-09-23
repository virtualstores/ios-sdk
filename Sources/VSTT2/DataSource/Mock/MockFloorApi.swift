//
//  FloorApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import VSFoundation

class MockFloorApi {}

extension MockFloorApi: IFloorApi {
  func getMapFence(url: String, completion: @escaping (Result<MapFence, Error>) -> ()) {
    completion(.success(.init(properties: .init(width: 500, height: 500), coordinates: [[[[0.0, 0.0], [500.0, 0.0], [500.0, 500.0], [0.0, 500.0], [0.0, 0.0]]]])))
  }

  func getMapZones(url: URL, completion: @escaping (Result<ZoneData, Error>) -> ()) {
    completion(.success(.init(mapZones: [], mapZonesPoints: [], sharedProperties: nil)))
  }

  func getNavGraph(url: URL, completion: @escaping (Result<Data?, Error>) -> ()) {
    completion(.success(nil))
  }

  func getShelfGroups(rtlsOptionsId: Int64, completion: @escaping (Result<[ShelfGroup], Error>) -> ()) {
    completion(.success([]))
  }
}
