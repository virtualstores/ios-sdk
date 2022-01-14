//
//  File.swift
//  
//
//  Created by Hripsime on 2022-01-13.
//

import Foundation
import Combine

final class UploadPositionsService: DataFetchingManager {
    func call(with parameters: UploadPositionsParameters) -> AnyPublisher<CreateVisitResponse, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
