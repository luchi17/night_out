import Foundation

//Remove: not used
private let userLoggedIn: String = "userLoggedIn"

extension UserDefaults {
    
    static func objectForKey(_ key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }

    static func setObject(_ object: Any?, forKey key: String) {
        guard object != nil else {
            if self.objectForKey(key) != nil { self.removeObjectForKey(key) }

            return
        }

        UserDefaults.standard.set(object, forKey: key)
    }

    static func removeObjectForKey(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    static func setUserLoggedin(_ enabled: Bool) {
        self.setObject(enabled, forKey: userLoggedIn)
    }

    static func isUserLoggedIn() -> Bool {
        self.objectForKey(userLoggedIn) as? Bool ?? false
    }
}
