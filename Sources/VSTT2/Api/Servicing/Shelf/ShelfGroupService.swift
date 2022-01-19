//
// ShelfGroupService
// VSTT2
//
// Created by Hripsime on 2022-01-12
// Copyright Virtual Stores - 2021

import Foundation
import Combine

final class ShelfGroupService: DataFetchingManager {
    func call(with parameters: ShelfGroupParameters) -> AnyPublisher<ShelfGroup, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
