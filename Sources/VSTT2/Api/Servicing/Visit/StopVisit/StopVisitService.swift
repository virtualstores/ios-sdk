//
//  StopVisitService.swift
//  
//
//  Created by Théodore Roos on 2022-03-26.
//

import Foundation
import Combine

final class StopVisitService: DataFetchingManager {
  func call(with parameters: StopVisitParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}
