//
// ItemPositionService
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import Combine

final class ItemPositionService: DataFetchingManager {
    func call(with parameters: ItemPositionParameters) -> AnyPublisher<[BarcodePosition], Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
