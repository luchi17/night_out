import Foundation

private let companies: String = "locationModels"
private let followModel: String = "followModel"

extension UserDefaults {
    
    static func objectForKey(_ key: String) -> Any? {
        // Obtener los datos almacenados
            if let savedData = UserDefaults.standard.data(forKey: key) {
                // Decodificar los datos a un FollowModel
                if let decoded = try? JSONDecoder().decode(FollowModel.self, from: savedData) {
                    return decoded
                }
            }
            return nil
    }

    static func setObject(_ object: Any?, forKey key: String) {
        guard object != nil else {
            if self.objectForKey(key) != nil {
                self.removeObjectForKey(key)
            }
            return
        }
        
        if let encoded = try? JSONEncoder().encode(followModel) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    static func removeObjectForKey(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    static func setCompanies(_ value: CompanyUsersModel) {
        self.setObject(value, forKey: companies)
    }

    static func getCompanies() -> CompanyUsersModel? {
        self.objectForKey(companies) as? CompanyUsersModel
    }
    
    static func setFollowModel(_ value: FollowModel) {
        self.setObject(value, forKey: followModel)
    }

    static func getFollowModel() -> FollowModel? {
        self.objectForKey(followModel) as? FollowModel
    }
}
