//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-20.
//

import Foundation
import Combine

final class StoresListService: DataFetchingManager {
    func call(with parameters: StoresListParameters) -> AnyPublisher<StoresList, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
