//
//  UserManager.swift
//
//
//  Created by Théodore Roos on 2024-05-29.
//

import Foundation
import VSFoundation

public protocol IUserManager {
  @available(*, deprecated, message: "Not in use anymore")
  func deleteUser(userId: String, completion: @escaping (Error?) -> ())
  @available(*, deprecated, message: "Not in use anymore")
  func initializeUser(userId: String, completion: @escaping (Error?) -> ())
  func setUser(profile: TT2UserProfile) -> TT2UserProfile
}

class UserManager {
  @Inject var setUser: SetUserProfileUseCase
}

extension UserManager: IUserManager {
  func deleteUser(userId: String, completion: @escaping (Error?) -> ()) {
    completion(nil)
  }

  func initializeUser(userId: String, completion: @escaping (Error?) -> ()) {
    completion(nil)
  }

  func setUser(profile: TT2UserProfile) -> TT2UserProfile {
    setUser.invoke(profile: profile)
    return profile
  }
}

public struct TT2UserProfile {
  public let userId: String
  public let tags: [String : String]

  public init(userId: String, tags: [String : String]) {
    self.userId = userId
    self.tags = tags
  }
}
