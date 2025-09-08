//
//  ClientsApi.swift
//  
//
//  Created by Théodore Roos on 2024-05-02.
//

import Foundation
import Combine
import VSFoundation

protocol IClientsApi: Disposable {
  func get(completion: @escaping (Result<[Client], Error>) -> Void)
}

class ClientsApi {
  private let tag = "ClientsApi"
  private let service = ClientsListService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension ClientsApi: IClientsApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellable.removeAll()
  }
  
  func get(completion: @escaping (Result<[Client], Error>) -> Void) {
    service
      .call(with: ClientsListParameters())
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error):
          if let error = error as? URLError {
            print("ErrorCode", error.errorCode)
            print("Code", error.code)
            print("UserInfo", error.userInfo)
            print("ErrorUserInfo", error.errorUserInfo)
            if error.errorCode == 401 {
              @Inject var refresh: RefreshUseCase
              refresh.invoke { (error) in
                self.get(completion: completion)
              }
            } else {
              completion(.failure(error))
            }
          }
          completion(.failure(error))
        }
      } receiveValue: { (data) in
        completion(.success(data.clients))
      }.store(in: &cancellable)
  }
}
