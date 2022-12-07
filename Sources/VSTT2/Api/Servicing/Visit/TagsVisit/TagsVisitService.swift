//
//  TagsVisitService.swift
//  
//
//  Created by Théodore Roos on 2022-12-07.
//

import Foundation
import Combine

final class TagsVisitService: DataFetchingManager {
  func call(with parameters: TagsVisitParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}
