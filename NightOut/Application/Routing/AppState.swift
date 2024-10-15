import SwiftUI
import Firebase
import FirebaseAuth
import Foundation

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false {
        didSet {
            // Guardar el estado de login en UserDefaults
            UserDefaults.setUserLoggedin(isLoggedIn)
        }
    }

    func checkUserStatus() {
        // Verificar si el usuario sigue autenticado en Firebase
        if let _ = Auth.auth().currentUser {
            // El usuario está autenticado, actualizar el estado
            self.isLoggedIn = true
        } else {
            // El usuario no está autenticado, actualizar el estado
            self.isLoggedIn = false
        }
    }
    
    func loadLoginState() {
        // Cargar el estado de login guardado en UserDefaults
        self.isLoggedIn = UserDefaults.isUserLoggedIn()
    }
}
