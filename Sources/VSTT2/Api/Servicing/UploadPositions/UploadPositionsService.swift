//
// UploadPositionsService
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import Combine

final class UploadPositionsService: DataFetchingManager {
    func call(with parameters: UploadPositionsParameters) -> AnyPublisher<Void, Error> {
        return self.executeEmptyBody(parameters, errorType: Error.self)
    }
}
