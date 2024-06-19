//
//  UploadDevicePostionService.swift
//
//
//  Created by Théodore Roos on 2024-06-18.
//

import Combine
import Foundation

final class UploadDevicePostionService: DataFetchingManager {
  func call(with parameters: UploadDevicePostionParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}
