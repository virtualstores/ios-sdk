//
//  UploadStepEventsService.swift
//  
//
//  Created by Théodore Roos on 2022-09-28.
//

import Foundation
import Combine

final class UploadStepEventsService: DataFetchingManager {
  func call(with parameters: UploadStepEventsParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self )
  }
}
