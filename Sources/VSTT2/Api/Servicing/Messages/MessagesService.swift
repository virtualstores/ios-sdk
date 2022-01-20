//
// MessagesService
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2021

import Foundation
import Combine

final class MessagesService: DataFetchingManager {
    func call(with parameters: MessagesParameters) -> AnyPublisher<[MessageDto], Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
