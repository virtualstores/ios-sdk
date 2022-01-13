//
//  File.swift
//  
//
//  Created by Hripsime on 2022-01-13.
//

import Foundation
import Combine

final class CreateVisitsService: DataFetchingManager {
    func call(with parameters: CreateVisitsParameters) -> AnyPublisher<CreateVisitResponse, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
