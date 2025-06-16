import Combine
import Foundation
import GoogleSignIn

protocol AccountRepository {
    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError>
    func loginGoogle() -> AnyPublisher<GIDGoogleUser, Error>
    func loginApple() -> AnyPublisher<Void, Error>
    func signup(email: String, password: String) -> AnyPublisher<String, SignupNetworkError>
    func signupCompany(email: String, password: String) -> AnyPublisher<String, SignupNetworkError>
    func saveUser(model: UserModel) -> AnyPublisher<Bool, Never>
    func saveCompany(model: CompanyModel) -> AnyPublisher<Bool, Never>
    func getUrlCompanyImage(imageData: Data) -> AnyPublisher<String?, Never>
    func signOut() -> AnyPublisher<Void, Error>
    func deleteAccount() -> AnyPublisher<String?, Never>
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never>
    func getCompanyInfo(uid: String) -> AnyPublisher<CompanyModel?, Never>
    func executeTerms() -> AnyPublisher<Bool, Never>
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never>
}

struct AccountRepositoryImpl: AccountRepository {
    static let shared: AccountRepository = AccountRepositoryImpl()

    private let network: AccountDatasource

    init(
        network: AccountDatasource = AccountDatasourceImpl()
    ) {
        self.network = network
    }

    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError> {
        return network
            .login(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    func signup(email: String, password: String) -> AnyPublisher<String, SignupNetworkError> {
        return network
            .signup(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    func signupCompany(email: String, password: String) -> AnyPublisher<String, SignupNetworkError> {
        return network
            .signupCompany(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    func executeTerms() -> AnyPublisher<Bool, Never> {
        return network
            .setTerms()
            .eraseToAnyPublisher()
    }
    
    func saveUser(model: UserModel) -> AnyPublisher<Bool, Never> {
        return network
            .saveUser(model: model)
            .eraseToAnyPublisher()
    }
    
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never> {
        return network
            .getUserInfo(uid: uid)
            .eraseToAnyPublisher()
    }
    
    func getCompanyInfo(uid: String) -> AnyPublisher<CompanyModel?, Never> {
        return network
            .getCompanyInfo(uid: uid)
            .eraseToAnyPublisher()
    }
    
    func saveCompany(model: CompanyModel) -> AnyPublisher<Bool, Never> {
        return network
            .saveCompany(model: model)
            .eraseToAnyPublisher()
    }
    
    func getUrlCompanyImage(imageData: Data) -> AnyPublisher<String?, Never> {
        return network
            .getUrlCompanyImage(imageData: imageData)
            .eraseToAnyPublisher()
    }
    
    func loginGoogle() -> AnyPublisher<GIDGoogleUser, Error> {
        return network
            .loginGoogle()
            .eraseToAnyPublisher()
    }
    
    func loginApple() -> AnyPublisher<Void, any Error> {
        return network
            .loginApple()
            .eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Void, Error> {
        return network
            .signOut()
            .eraseToAnyPublisher()
    }
    
    func deleteAccount() -> AnyPublisher<String?, Never> {
        return network
            .deleteAccount()
            .eraseToAnyPublisher()
    }
    
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never> {
        return network
            .findUserByEmail(email)
            .eraseToAnyPublisher()
    }
}
