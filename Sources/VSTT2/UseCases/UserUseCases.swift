//
//  UserUseCases.swift
//
//
//  Created by Théodore Roos on 2024-05-29.
//

import Foundation
import VSFoundation

class GetUserProfileUseCase {
  @Inject var repository: IUserRepository

  func invoke() -> TT2UserProfile? {
    repository.getUserProfile()
  }
}

class SetUserProfileUseCase {
  @Inject var repository: IUserRepository

  func invoke(profile: TT2UserProfile) {
    repository.setUser(profile: profile)
  }
}
