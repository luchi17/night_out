import Foundation

private let companies: String = "locationModels"
private let followModel: String = "followModel"
private let userModel: String = "userModel"
private let companyModel: String = "companyModel"

extension UserDefaults {
    
    static func objectForKey<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error al decodificar el objeto: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func setObject<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error al codificar el objeto: \(error.localizedDescription)")
        }
    }
    
    static func clearAll() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
            dictionary.keys.forEach { key in
                defaults.removeObject(forKey: key)
            }
        guard let appDomain = Bundle.main.bundleIdentifier else {
            print("Could not clean appDomain")
            return
        }
        UserDefaults.standard.removePersistentDomain(forName: appDomain)
        UserDefaults.standard.synchronize()
    }
    
    static func removeObjectForKey(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    static func setCompanies(_ value: CompanyUsersModel) {
        self.setObject(value, forKey: companies)
    }
    
    static func getCompanies() -> CompanyUsersModel? {
        self.objectForKey(forKey: companies, as: CompanyUsersModel.self)
    }
    
    static func setFollowModel(_ value: FollowModel) {
        self.setObject(value, forKey: followModel)
    }
    
    static func getFollowModel() -> FollowModel? {
        self.objectForKey(forKey: companies, as: FollowModel.self)
    }
    
    static func setUserModel(_ value: UserModel) {
        self.setObject(value, forKey: userModel)
    }
    
    static func getUserModel() -> UserModel? {
        self.objectForKey(forKey: userModel, as: UserModel.self)
    }
    
    static func setCompanyUserModel(_ value: CompanyModel) {
        self.setObject(value, forKey: companyModel)
    }
    
    static func getCompanyUserModel() -> CompanyModel? {
        self.objectForKey(forKey: companyModel, as: CompanyModel.self)
    }
}
