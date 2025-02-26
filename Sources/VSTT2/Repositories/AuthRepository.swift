//
//  AuthRepository.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-02-03.
//

protocol IAuthRepository {
  func getAuthSettings() -> AuthSettings?
  func login(username: String, password: String, completion: @escaping (Result<LoginDto, Error>) -> Void)
  func refresh(authToken: String, refreshToken: String, completion: @escaping (Result<RefreshDto, Error>) -> ())
  func set(authSettings: AuthSettings?)
}

class AuthRepository {
  let api: IAuthApi = AuthApi()
  private var authSettings: AuthSettings?
}

extension AuthRepository: IAuthRepository {
  func getAuthSettings() -> AuthSettings? {
    authSettings
  }

  func login(username: String, password: String, completion: @escaping (Result<LoginDto, Error>) -> Void) {
    api.login(username: username, password: password, completion: completion)
  }

  func refresh(authToken: String, refreshToken: String, completion: @escaping (Result<RefreshDto, Error>) -> ()) {
    api.refresh(authToken: authToken, refreshToken: refreshToken, completion: completion)
  }

  func set(authSettings: AuthSettings?) {
    self.authSettings = authSettings
  }
}

public enum AuthSettings {
  case apiKey(String)
  case tokenBased(TokenBased)

  public struct TokenBased {
    let username: String
    let password: String

    public init(username: String, password: String) {
      self.username = username
      self.password = password
    }
  }
}
