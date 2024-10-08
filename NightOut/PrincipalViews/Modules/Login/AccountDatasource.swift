import Combine
import Foundation
import FirebaseAuth

protocol AccountDatasource {
    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError>
}

struct AccountDatasourceImpl: AccountDatasource {
    func login(email: String, password: String) -> AnyPublisher<Void, LoginNetworkError> {
        // Aquí, primero comprobamos si el email y la contraseña son válidos
        guard !email.isEmpty, !password.isEmpty else {
            return Fail(error: .invalidCredentials)
                .eraseToAnyPublisher() // Emitir un resultado sin error
        }
        
        let publisher = PassthroughSubject<Void, LoginNetworkError>()
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // Mapeo de errores de Firebase a NetworkError
                if (error as NSError).code == AuthErrorCode.wrongPassword.rawValue {
                    publisher.send(completion: .failure(.invalidCredentials))
                } else {
                    publisher.send(completion: .failure(.unknown(error)))
                }
            } else {
                // Login exitoso
                publisher.send()
                publisher.send(completion: .finished)
            }
        }
        return publisher.eraseToAnyPublisher()
    }
}

// Define tu NetworkError
enum LoginNetworkError: Error {
    case invalidCredentials
    case unknown(Error)
}
