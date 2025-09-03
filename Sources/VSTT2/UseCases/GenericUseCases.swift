//
//  GenericUseCases.swift
//  VSTT2
//
//  Created by Théodore Roos on 2024-11-05.
//

import VSFoundation

class StopTT2UseCase {
  @Inject var analytics: TT2AnalyticsManager
  @Inject var navigation: Navigation

  func invoke(leaseExpired: Bool = false) {
    navigation.stop()
    analytics.stopCollectingHeatMapData()
    analytics.leaseExpired = leaseExpired
    analytics.stopVisit()
  }
}

class CreateLoggerUseCase {
  @Inject var repository: IStatusRepository

  func invoke(verbosity: Verbosity) -> Logger? {
    if repository.currentSettings.debugModeEnabled {
      return Logger(verbosity: verbosity)
    }
    return nil
  }
}
