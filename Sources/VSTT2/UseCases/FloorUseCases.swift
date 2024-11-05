//
//  FloorUseCases.swift
//
//
//  Created by Théodore Roos on 2024-05-23.
//

import Foundation
import VSFoundation

// MARK: - Fetchers

class FetchMapFenceUseCase {
  @Inject var repository: IFloorRepository

  func invoke(completion: @escaping (Error?) -> ()) {
    repository.fetchMapFence(completion: completion)
  }
}

class FetchMapZonesUseCase {
  @Inject var repository: IFloorRepository

  func invoke(completion: @escaping (Error?) -> ()) {
    repository.fetchMapZones(completion: completion)
  }
}

class FetchNavGraphUseCase {
  @Inject var repository: IFloorRepository

  func invoke(completion: @escaping (Error?) -> ()) {
    repository.fetchNavGraph(completion: completion)
  }
}

class FetchShelfGroupsUseCase {
  @Inject var repository: IFloorRepository

  func invoke(completion: @escaping (Error?) -> ()) {
    repository.fetchShelfGroups(completion: completion)
  }
}

// MARK: - Getters

class GetActiveCoordinateConverterUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> ICoordinateConverter? {
    repository.activeConverter
  }
}

class GetActiveFloorUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> RtlsOptions {
    repository.activeFloor
  }
}

class GetActiveMapFenceUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> MapFence? {
    repository.activeMapFence
  }
}

class GetActiveMapZonesUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> ZoneData? {
    repository.activeMapZones
  }
}

class GetActiveNavGraphUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> Data? {
    repository.activeNavGraph
  }
}

class GetActiveShelfGroupsUseCase {
  @Inject var repository: IFloorRepository

  func invoke() -> [ShelfGroup]? {
    repository.activeShelfGroups
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
