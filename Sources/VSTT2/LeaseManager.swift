//
//  LeaseController.swift
//  VSTT2
//
//  Created by Théodore Roos on 2024-11-04.
//

import Combine
import Foundation
import VSFoundation

public protocol ILeaseManager {
  var onLeaseExpiredPublisher: CurrentValueSubject<Void, Never> { get }
  var hasLease: Bool { get }
  var timeLeftOnLeaseInSeconds: Double { get }

  func start(policy: LeasePolicyEnum, initialLeaseTimeInSeconds: Double, maxLeaseTimeInSeconds: Double?)
  func stop()
  func extend(leaseTimeInSeconds: Double)
}

public extension ILeaseManager {
  func start(policy: LeasePolicyEnum, initialLeaseTimeInSeconds: Double, maxLeaseTimeInSeconds: Double? = nil) {
    start(policy: policy, initialLeaseTimeInSeconds: initialLeaseTimeInSeconds, maxLeaseTimeInSeconds: maxLeaseTimeInSeconds)
  }
}

public enum LeasePolicyEnum: String {
  case handleManually = "HANDLE_MANUALLY"
  case stopVisit = "STOP_VISIT"
}

class LeaseManager {
  @Inject var stopTT2: StopTT2UseCase
  @Inject var setLeaseExpired: SetLeaseExpiredUseCase
  @Inject var setLeasePolicy: SetLeasePolicyUseCase

  private var _onLeaseExpiredPublisher: CurrentValueSubject<Void, Never> = .init(())

  private var lease: Lease?
  private var leaseTimer: Timer?
}

private extension LeaseManager {
  func startLease() {
    leaseTimer?.invalidate()
    leaseTimer = nil
    leaseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] (_) in
      guard let self = self, let lease = lease else { self?.stop(); return }
      guard lease.hasExpired else { return }
      onLeaseExpiredPublisher.send(())
      setLeaseExpired.invoke(leaseExpired: true)
      switch lease.policy {
      case .handleManually: break
      case .stopVisit: stopTT2.invoke()
      }
      stop()
    }
  }

  struct Lease {
    let policy: LeasePolicyEnum
    let expirationTime: Double
    let maxLeaseTime: Double?
    var hasExpired: Bool { Date().timeIntervalSince1970 > expirationTime }
    var timeRemaining: Double { expirationTime - Date().timeIntervalSince1970 }
  }
}

extension LeaseManager: ILeaseManager {
  var onLeaseExpiredPublisher: CurrentValueSubject<Void, Never> { _onLeaseExpiredPublisher }
  var hasLease: Bool { lease != nil }
  var timeLeftOnLeaseInSeconds: Double { lease?.timeRemaining ?? -1 }

  func start(policy: LeasePolicyEnum, initialLeaseTimeInSeconds: Double, maxLeaseTimeInSeconds: Double?) {
    let expirationTime: Double
    if let maxTime = maxLeaseTimeInSeconds, initialLeaseTimeInSeconds > maxTime {
      expirationTime = Date().timeIntervalSince1970 + maxTime
    } else {
      expirationTime = Date().timeIntervalSince1970 + initialLeaseTimeInSeconds
    }
    lease = .init(
      policy: policy,
      expirationTime: expirationTime,
      maxLeaseTime: maxLeaseTimeInSeconds
    )
    setLeaseExpired.invoke(leaseExpired: false)
    setLeasePolicy.invoke(policy: policy)
    startLease()
  }

  func stop() {
    leaseTimer?.invalidate()
    leaseTimer = nil
    lease = nil
  }

  func extend(leaseTimeInSeconds: Double) {
    guard let lease = lease else { return }
    var expirationTime = lease.expirationTime + leaseTimeInSeconds
    if let maxLeaseTime = lease.maxLeaseTime, expirationTime > Date().timeIntervalSince1970 + maxLeaseTime {
      Logger(verbosity: .info).log(message: "Extending lease exceeds max lease time, lease set to maxLeaseTime")
      expirationTime = Date().timeIntervalSince1970 + maxLeaseTime
    }
    self.lease = .init(policy: lease.policy, expirationTime: expirationTime, maxLeaseTime: lease.maxLeaseTime)
  }
}
