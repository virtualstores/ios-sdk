//
//  JWTRepository.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-01-30.
//

protocol IJWTTokenRepository {
  func clearAllTokens()
  func getAuthJWT() -> String?
  func getRefreshJWT() -> String?
  func save(accessJWT token: String)
  func save(refreshJWT token: String)
}

class JWTTokenRepository {
  private var authJWTToken: String?
  private var refreshJWTToken: String?
}

extension JWTTokenRepository: IJWTTokenRepository {
  func clearAllTokens() {
    authJWTToken = nil
    refreshJWTToken = nil
  }

  func getAuthJWT() -> String? {
    authJWTToken
  }

  func getRefreshJWT() -> String? {
    refreshJWTToken
  }

  func save(accessJWT token: String) {
    authJWTToken = token
  }
  
  func save(refreshJWT token: String) {
    refreshJWTToken = token
  }
}
