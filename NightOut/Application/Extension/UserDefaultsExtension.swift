import Foundation

private let companies: String = "locationModels"
private let followModel: String = "followModel"

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
        guard let appDomain = Bundle.main.bundleIdentifier else { return }
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
}
