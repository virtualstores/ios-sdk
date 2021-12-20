//
// NavigationSpaceWebService
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation
import Combine

final class NavigationSpaceWebService: DataFetchingManager {
    func call(with parameters: NavigationSpaceParameters) -> AnyPublisher<NavigationSpace, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
