//
//  StatusUseCases.swift
//
//
//  Created by Théodore Roos on 2024-09-02.
//

import Combine
import Foundation
import VSFoundation

class GetCurrentCompassHeadingUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> Double? {
    repository.currentCompassHeading
  }
}

class GetCurrentGPSLocationUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> VPSOutputSignal.LatLngPosition.Location? {
    repository.currentGPSLocation
  }
}

class GetCurrentLeasePolicyUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> LeasePolicyEnum? {
    repository.currentLeasePolicy
  }
}

class GetCurrentVPSPositionUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> VPSOutputSignal.Position? {
    repository.currentPosition
  }
}

class GetCurrentTT2SettingsUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> TT2Settings {
    repository.currentSettings
  }
}

class GetIsVPSRunningUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> Bool {
    repository.isVPSRunning
  }
}

class SetCompassHeadingUseCase {
  @Inject var repository: IStatusRepository

  func invoke(compassHeading: Double) {
    repository.set(compassHeading: compassHeading)
  }
}

class SetGPSPositionUseCase {
  @Inject var repository: IStatusRepository

  func invoke(gpsPosition: VPSOutputSignal.LatLngPosition.Location) {
    repository.set(gpsPosition: gpsPosition)
  }
}

class SetLeasePolicyUseCase {
  @Inject var repository: IStatusRepository

  func invoke(policy: LeasePolicyEnum) {
    repository.set(policy: policy)
  }
}

class SetVPSPositionUseCase {
  @Inject var repository: IStatusRepository

  func invoke(vpsPosition: VPSOutputSignal.Position) {
    repository.set(vpsPosition: vpsPosition)
  }
}

class SetIsVPSRunningUseCase {
  @Inject var repository: IStatusRepository

  func invoke(isVPSRunning: Bool, qrStart: Bool) {
    repository.set(isVPSRunning: isVPSRunning, qrStart: qrStart)
  }
}

class SetTT2SettingsUseCase {
  @Inject var repository: IStatusRepository
  @Inject var analytics: IAnalyticsRepository
  @Inject var cient: IClientRepository
  @Inject var floor: IFloorRepository
  @Inject var store: IStoreRepository
  @Inject var eventManager: TT2EventManager

  func invoke(settings: TT2Settings) {
    repository.set(settings: settings)
    (analytics as? IStatusTT2Settings)?.update(with: settings)
    (cient as? IStatusTT2Settings)?.update(with: settings)
    (floor as? IStatusTT2Settings)?.update(with: settings)
    (store as? IStatusTT2Settings)?.update(with: settings)
    eventManager.update(with: settings)
  }
}

class SubscribeToCompassHeadingUpdatesUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> AnyPublisher<Double?, Never> {
    repository.compassHeadingPublisher()
  }
}

class SubscribeToGPSUpdatesUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> AnyPublisher<VPSOutputSignal.LatLngPosition.Location?, Never> {
    repository.gpsPositionPublisher()
  }
}

class SubscribeToVPSUpdatesUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> AnyPublisher<VPSOutputSignal.Position?, Never> {
    repository.vpsPositionPublisher()
  }
}

class SubscribeToIsVPSRunningUseCase {
  @Inject var repository: IStatusRepository

  func invoke() -> AnyPublisher<(running: Bool, isReferenceAngleCertain: Bool), Never> {
    repository.isVPSRunningPublisher()
  }
}
