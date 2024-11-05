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

  func start(policy: LeasePolicy, initialLeaseTimeInSeconds: Double)
  func stop()
  func extend(leaseTimeInSeconds: Double)
}

public enum LeasePolicy {
  case handleManually, stopVisit
}

class LeaseManager {
  @Inject var stopTT2: StopTT2UseCase

  private var _onLeaseExpiredPublisher: CurrentValueSubject<Void, Never> = .init(())
  private var hasLease: Bool { lease != nil }
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
      switch lease.policy {
      case .handleManually:
        break
      case .stopVisit:
        stopTT2.invoke(leaseExpired: true)
      }
      stop()
    }
  }

  struct Lease {
    let policy: LeasePolicy
    let expirationTime: Double
    var hasExpired: Bool { Date().timeIntervalSince1970 > expirationTime }
  }
}

extension LeaseManager: ILeaseManager {
  var onLeaseExpiredPublisher: CurrentValueSubject<Void, Never> { _onLeaseExpiredPublisher }

  func start(policy: LeasePolicy, initialLeaseTimeInSeconds: Double) {
    lease = .init(policy: policy, expirationTime: Date().timeIntervalSince1970 + initialLeaseTimeInSeconds)
    startLease()
  }

  func stop() {
    lease = nil
    leaseTimer?.invalidate()
    leaseTimer = nil
  }

  func extend(leaseTimeInSeconds: Double) {
    guard let lease = lease else { return }
    self.lease = .init(policy: lease.policy, expirationTime: lease.expirationTime + leaseTimeInSeconds)
  }
}
