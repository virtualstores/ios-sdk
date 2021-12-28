//
// MapFenceDataService
// VSTT2
//
// Created by Hripsime on 2021-12-21
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation
import Combine

final class MapFenceDataService: DataFetchingManager {
    func call(with parameters: MapFenceDataParameters) -> AnyPublisher<MapFence, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
