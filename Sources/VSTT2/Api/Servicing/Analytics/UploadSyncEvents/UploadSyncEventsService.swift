//
//  UploadSyncEventsService.swift
//  
//
//  Created by Théodore Roos on 2022-09-19.
//

import Foundation
import Combine

final class UploadSyncEventsService: DataFetchingManager {
  func call(with parameters: UploadSyncEventParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}
