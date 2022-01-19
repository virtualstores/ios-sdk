//
// UploadScanEventsService
// VSTT2
//
// Created by Hripsime on 2022-01-19.
// Copyright Virtual Stores - 2021

import Foundation
import Combine

final class UploadScanEventsService: DataFetchingManager {
    func call(with parameters: UploadScanEventsParameters) -> AnyPublisher<Void, Error> {
        return self.executeEmptyBody(parameters, errorType: Error.self)
    }
}
