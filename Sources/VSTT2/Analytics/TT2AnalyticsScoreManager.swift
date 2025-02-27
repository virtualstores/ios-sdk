//
//  TT2AnalyticsScoreManager.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-02-26.
//

import Foundation
import VSFoundation

struct VisitScore {
  let score: Int
  let isAccepted: Bool
  let timestamp: Date
}

extension VisitScore: Equatable {
  static func != (lhs: VisitScore, rhs: VisitScore) -> Bool {
    return lhs.score != rhs.score && lhs.isAccepted != rhs.isAccepted
  }
}

class TT2AnalyticsScoreManager {
  @Inject var uploadVisitScore: UploadVisitScoreForActiveVisitUseCase
  @Inject var validateVisitScore: ValidateVisitScoreUseCase
  private var latestVisitScore: VisitScore?
  private var latestUploadedVisitScore: VisitScore?
  private var lastUploadTimestamp: Date = .init()
  private var uploadIntervalThreshold: Double = 15

  func report(score: Int) {
    guard let visitScore = validateVisitScore.invoke(score: score, timestamp: .init()) else { return }
    latestVisitScore = visitScore
    if visitScore.timestamp.timeIntervalSince1970 - lastUploadTimestamp.timeIntervalSince1970 >= uploadIntervalThreshold, visitScore != latestUploadedVisitScore {
      lastUploadTimestamp = .init()
      upload(visitScore: visitScore)
    }
  }

  func upload(visitScore: VisitScore) {
    uploadVisitScore.invoke(visitScore: visitScore) { [weak self] (error) in
      if let error = error {
        Logger(verbosity: .debug).log(message: error.localizedDescription)
      } else {
        Logger(verbosity: .debug).log(message: "UploadVisitScore Success: \(visitScore.score)")
        self?.latestUploadedVisitScore = visitScore
      }
    }
  }

  func startVisit() {
    reset()
  }

  func stopVisit() {
    guard
      let visitScore = latestVisitScore,
      visitScore != latestUploadedVisitScore
    else { return }
    upload(visitScore: visitScore)
    reset()
  }

  func reset() {
    latestVisitScore = nil
    latestUploadedVisitScore = nil
    lastUploadTimestamp = .init()
  }
}
