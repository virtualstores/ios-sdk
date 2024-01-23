//
//  UploadGeoPositionsService.swift
//  
//
//  Created by Théodore Roos on 2023-12-14.
//

import Foundation
import Combine

final class UploadGeoPositionsService: DataFetchingManager {
  func call(with parameters: UploadGeoPositionsParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}
