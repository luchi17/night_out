import Combine
import Foundation

protocol AccountRepository {
    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError>
    func loginGoogle() -> AnyPublisher<Void, Error>
    func loginApple() -> AnyPublisher<Void, Error>
    func signup(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError>
    func signupCompany(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError>
    func saveUser(model: UserModel) -> AnyPublisher<Bool, Never>
    func saveCompany(model: CompanyModel) -> AnyPublisher<Bool, Never>
    func signOut() -> AnyPublisher<Void, Error>
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
    
    func signup(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError> {
        return network
            .signup(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    func signupCompany(email: String, password: String) -> AnyPublisher<Void, SignupNetworkError> {
        return network
            .signupCompany(email: email, password: password)
            .eraseToAnyPublisher()
    }
    
    func saveUser(model: UserModel) -> AnyPublisher<Bool, Never> {
        return network
            .saveUser(model: model)
            .eraseToAnyPublisher()
    }
    
    func saveCompany(model: CompanyModel) -> AnyPublisher<Bool, Never> {
        return network
            .saveCompany(model: model)
            .eraseToAnyPublisher()
    }
    
    func loginGoogle() -> AnyPublisher<Void, Error> {
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
    
    
}
