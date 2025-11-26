//
//  FloorUseCases.swift
//
//
//  Created by Théodore Roos on 2024-05-23.
//

import Combine
import Foundation
import VSFoundation
import VSPositionKit

class CreateVPSPathfindersUseCase {
  @Inject var repository: IFloorRepository

  func invoke() {
    repository.createVPSPathfinders()
  }
}


// MARK: - Fetchers

class FetchMapFenceUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> AnyPublisher<Void, Error> {
    repository.fetchMapFence()
  }
}

class FetchMapZonesUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> AnyPublisher<Void, Error> {
    repository.fetchMapZones()
  }
}

class FetchNavGraphUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> AnyPublisher<Void, Error> {
    repository.fetchNavGraph()
  }
}

class FetchShelfGroupsUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> AnyPublisher<Void, Error> {
    repository.fetchShelfGroups()
  }
}

// MARK: - Getters

class GetActiveCoordinateConverterUseCase {
  @Inject var repository: IFloorRepository

  func invoke() throws -> ICoordinateConverter? {
    try repository.activeConverter
  }
}

class GetActiveFloorUseCase {
  @Inject var repository: IFloorRepository

  func invoke() throws -> RtlsOptions {
    try repository.activeFloor
  }
}

class GetActiveMapFenceUseCase {
  @Inject var repository: IFloorRepository

  func invoke() throws -> MapFence? {
    try repository.activeMapFence
  }
}

class GetActiveMapZonesUseCase {
  @Inject var repository: IFloorRepository

  func invoke() throws -> ZoneData? {
    try repository.activeMapZones
  }
}

class GetActiveNavGraphUseCase {
  @Inject var repository: IFloorRepository

  func invoke() throws -> Data? {
    try repository.activeNavGraph
  }
}

class GetActivePathfinderUseCase {
  @Inject var repository: IFloorRepository

  func invoke() throws -> VPSPathfinderAdapter? {
    try repository.activeVpsPathfinder
  }
}

class GetActiveShelfGroupsUseCase {
  @Inject var repository: IFloorRepository

  func invoke() throws -> [ShelfGroup]? {
    try repository.activeShelfGroups
  }
}

class GetCachedFloorsUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> [RtlsOptions] {
    repository.getRtlsOptions()
  }
}

class GetMapZonesUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> [Int64: ZoneData] {
    repository.getMapZones()
  }
}

// MARK: - Setters

class SetActiveFloorUseCase {
  @Inject var repository: IFloorRepository

  func invoke(rtlsOptionsId: Int64) {
    guard let floor = repository.getRtlsOptions().first(where: { $0.id == rtlsOptionsId}) else { return }
    repository.set(activeFloor: floor)
  }
}

class SetFloorsUseCase {
  @Inject var repository: IFloorRepository

  func invoke(cachedFloors: [RtlsOptions]) {
    repository.set(cachedFloors: cachedFloors)
  }
}
