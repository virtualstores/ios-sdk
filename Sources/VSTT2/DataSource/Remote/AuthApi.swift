//
//  AuthApi.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-02-03.
//

import Combine
import VSFoundation

protocol IAuthApi: Disposable {
  func login(username: String, password: String, completion: @escaping (Result<LoginDto, Error>) -> ())
  func refresh(authToken: String, refreshToken: String) -> AnyPublisher<RefreshDto, Error>
}

class AuthApi {
  private let tag = "AuthApi"
  private let loginService = LoginService(with: NetworkManager())
  private let refreshService = RefreshService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension AuthApi: IAuthApi {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellable.removeAll()
  }
  
  func login(username: String, password: String, completion: @escaping (Result<LoginDto, Error>) -> ()) {
    loginService
      .call(with: .init(username: username, password: password))
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellable)
  }

  func refresh(authToken: String, refreshToken: String) -> AnyPublisher<RefreshDto, Error> {
    refreshService
      .call(with: .init(authToken: authToken, refreshToken: refreshToken))
      .share()
      .eraseToAnyPublisher()
  }
}
