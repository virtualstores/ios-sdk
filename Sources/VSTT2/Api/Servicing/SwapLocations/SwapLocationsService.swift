//
// SwapLocationsParameters
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import VSFoundation

final class SwapLocationsService: DataFetchingManager {
    func call(with parameters: SwapLocationsParameters) -> AnyPublisher<[SwapLocation], Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
