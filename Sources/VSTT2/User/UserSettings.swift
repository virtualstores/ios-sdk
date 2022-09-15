//
// UserSettings
// ITT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

private class UserSettings: IUserSettings {
    @Inject var persistence: Persistence

    public func setUser(user: User) {
        setUser(user: user.asTT2User)
    }

    public func setUser(user: TT2User) {
        var object = user
        do {
            try persistence.save(&object)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Save User Object SQLite error")
        }
    }
    
    public func getUser(userId: String) -> User? {
        let users = persistence.get(arrayOf: TT2User.self)
        let tt2User = users.first(where: { $0.userId == userId })
        
        let user = User(id: tt2User?.id, userId: tt2User?.userId, height: tt2User?.height, name: tt2User?.name, age: tt2User?.age, gender: tt2User?.gender)
                        
        return user
    }
    
    public func getLastUser() -> TT2User? {
        let users = persistence.get(arrayOf: TT2User.self)
        
        return users.last ?? nil
    }
    
    public func clearAllUserSettings() { }
    
    public func clearUser(userId: String) {
        let users = persistence.get(arrayOf: TT2User.self)
        guard let user = users.first(where: { $0.userId == userId }) else { return }
        
        do {
            try persistence.delete(user)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Remove User error")
        }
    }
}

public extension User {
  var asTT2User: TT2User {
    let user = TT2User()
    user.setup(id: id, userId: userId, height: height, name: name, age: age, gender: gender)
    return user
  }
}
