//
//  TriggerEventsService.swift
//  
//
//  Created by Théodore Roos on 2022-04-11.
//

import Foundation
import Combine

final class TriggerEventsService: DataFetchingManager {
  func call(with parameters: TriggerEventsParameters) -> AnyPublisher<[TriggerEventDto], Error> {
    self.execute(parameters, errorType: Error.self)
  }
}
