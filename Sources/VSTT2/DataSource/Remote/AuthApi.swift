//
//  AuthApi.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-02-03.
//

import Combine
import VSFoundation

protocol IAuthApi {
  func login(username: String, password: String) -> AnyPublisher<LoginDto, Error>
  func refresh(authToken: String, refreshToken: String) -> AnyPublisher<RefreshDto, Error>
}

class AuthApi {
  private let loginService = LoginService(with: NetworkManager())
  private let refreshService = RefreshService(with: NetworkManager())
}

extension AuthApi: IAuthApi {
  func login(username: String, password: String) -> AnyPublisher<LoginDto, Error> {
    loginService.call(with: .init(username: username, password: password))
  }

  func refresh(authToken: String, refreshToken: String) -> AnyPublisher<RefreshDto, Error> {
    refreshService
      .call(with: .init(authToken: authToken, refreshToken: refreshToken))
      .share()
      .eraseToAnyPublisher()
  }
}
