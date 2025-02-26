//
//  AuthApi.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-02-03.
//

import Combine

protocol IAuthApi {
  func login(username: String, password: String, completion: @escaping (Result<LoginDto, Error>) -> ())
  func refresh(authToken: String, refreshToken: String, completion: @escaping (Result<RefreshDto, Error>) -> ())
}

class AuthApi {
  private let loginService = LoginService(with: NetworkManager())
  private let refreshService = RefreshService(with: NetworkManager())
  private var cancellable = Set<AnyCancellable>()
}

extension AuthApi: IAuthApi {
  func login(username: String, password: String, completion: @escaping (Result<LoginDto, Error>) -> ()) {
    loginService
      .call(with: .init(username: username, password: password))
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      } receiveValue: { (data) in
        completion(.success(data))
      }.store(in: &cancellable)
  }

  func refresh(authToken: String, refreshToken: String, completion: @escaping (Result<RefreshDto, Error>) -> ()) {
    refreshService
      .call(with: .init(authToken: authToken, refreshToken: refreshToken))
      .share()
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      } receiveValue: { (data) in
        completion(.success(data))
      }.store(in: &cancellable)
  }
}
