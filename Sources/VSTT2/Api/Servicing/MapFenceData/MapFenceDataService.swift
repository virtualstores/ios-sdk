//
// MapFenceDataService
// VSTT2
//
// Created by Hripsime on 2021-12-21
// Copyright Virtual Stores - 2021

import Foundation
import Combine

final class MapFenceDataService: DataFetchingManager {
    func call(with parameters: MapFenceDataParameters) -> AnyPublisher<Mapfence, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
