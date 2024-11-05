//
//  UserRepository.swift
//
//
//  Created by Théodore Roos on 2024-05-29.
//

import Foundation

protocol IUserRepository {
  func getUserProfile() -> TT2UserProfile?
  func setUser(profile: TT2UserProfile)
}

class UserRepository {
  var profile: TT2UserProfile?
}

extension UserRepository: IUserRepository {
  func getUserProfile() -> TT2UserProfile? {
    profile
  }
  
  func setUser(profile: TT2UserProfile) {
    self.profile = profile
  }
}
