//
// UploadPositionsService
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import SQLite

final class UploadTriggersService: DataFetchingManager {
    func call(with parameters: UploadTriggersParameters) -> AnyPublisher<CreateVisitResponse, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
