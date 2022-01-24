//
// OrdersService
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import Combine

final class OrdersService: DataFetchingManager {
    func call(with parameters: OrdersParameters) -> AnyPublisher<Void, Error> {
        return self.executeEmptyBody(parameters, errorType: Error.self)
    }
}
