//
//  StatusRepository.swift
//
//
//  Created by Théodore Roos on 2024-09-02.
//

import Combine
import CoreGraphics
import Foundation
import VSFoundation

protocol IStatusTT2Settings {
  func update(with settings: TT2Settings)
}

protocol IStatusRepository {
  var currentCompassHeading: Double? { get }
  var currentGPSLocation: VPSOutputSignal.LatLngPosition.Location? { get }
  var currentLeasePolicy: LeasePolicyEnum? { get }
  var currentPosition: VPSOutputSignal.Position? { get }
  var currentSettings: TT2Settings { get }
  var isVPSRunning: Bool { get }
  func set(compassHeading: Double)
  func set(gpsPosition: VPSOutputSignal.LatLngPosition.Location)
  func set(policy: LeasePolicyEnum)
  func set(vpsPosition: VPSOutputSignal.Position)
  func set(isVPSRunning: Bool, qrStart: Bool)
  func set(settings: TT2Settings)
  func compassHeadingPublisher() -> AnyPublisher<Double?, Never>
  func gpsPositionPublisher() -> AnyPublisher<VPSOutputSignal.LatLngPosition.Location?, Never>
  func vpsPositionPublisher() -> AnyPublisher<VPSOutputSignal.Position?, Never>
  func isVPSRunningPublisher() -> AnyPublisher<(running: Bool, isReferenceAngleCertain: Bool), Never>
}

class StatusRepository {
  private var currentCompassHeadingPublisher: CurrentValueSubject<Double?, Never> = .init(nil)
  private var currentGPSLocationPublisher: CurrentValueSubject<VPSOutputSignal.LatLngPosition.Location?, Never> = .init(nil)
  private var _currentLeasePolicy: LeasePolicyEnum?
  private var currentPositionPublisher: CurrentValueSubject<VPSOutputSignal.Position?, Never> = .init(nil)
  private var _currentSettings: TT2Settings = .init()
  private var isVPSRunningSubscriber: CurrentValueSubject<(running: Bool, isReferenceAngleCertain: Bool), Never> = .init((running: false, isReferenceAngleCertain: false))
}

extension StatusRepository: IStatusRepository {
  var currentCompassHeading: Double? { currentCompassHeadingPublisher.value }
  var currentGPSLocation: VPSOutputSignal.LatLngPosition.Location? { currentGPSLocationPublisher.value }
  var currentLeasePolicy: LeasePolicyEnum? { _currentLeasePolicy }
  var currentPosition: VPSOutputSignal.Position? { currentPositionPublisher.value }
  var currentSettings: TT2Settings { _currentSettings }
  var isVPSRunning: Bool { isVPSRunningSubscriber.value.running }

  func set(compassHeading: Double) {
    currentCompassHeadingPublisher.send(compassHeading)
  }

  func set(gpsPosition: VPSOutputSignal.LatLngPosition.Location) {
    currentGPSLocationPublisher.send(gpsPosition)
  }

  func set(policy: LeasePolicyEnum) {
    _currentLeasePolicy = policy
  }

  func set(vpsPosition: VPSOutputSignal.Position) {
    currentPositionPublisher.send(vpsPosition)
  }

  func set(isVPSRunning: Bool, qrStart: Bool) {
    isVPSRunningSubscriber.send((isVPSRunning, qrStart))
  }

  func set(settings: TT2Settings) {
    _currentSettings = settings
  }

  func compassHeadingPublisher() -> AnyPublisher<Double?, Never> {
    currentCompassHeadingPublisher.eraseToAnyPublisher()
  }

  func gpsPositionPublisher() -> AnyPublisher<VPSOutputSignal.LatLngPosition.Location?, Never> {
    currentGPSLocationPublisher.eraseToAnyPublisher()
  }

  func vpsPositionPublisher() -> AnyPublisher<VPSOutputSignal.Position?, Never> {
    currentPositionPublisher.eraseToAnyPublisher()
  }

  func isVPSRunningPublisher() -> AnyPublisher<(running: Bool, isReferenceAngleCertain: Bool), Never> {
    isVPSRunningSubscriber.eraseToAnyPublisher()
  }
}
