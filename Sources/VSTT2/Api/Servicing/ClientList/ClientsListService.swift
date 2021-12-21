//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-20.
//

import Foundation
import Combine

final class ClientsListService: DataFetchingManager {
    func call(with parameters: ClientsListParameters) -> AnyPublisher<ClientsList, Error> {
        return self.execute(parameters, errorType: Error.self)
    }
}
