import UIKit
import Firebase
import Foundation
import FirebaseAuth
import FirebaseDatabase
import SwiftUI

final class FirebaseServiceImpl: ObservableObject {
    static let shared = FirebaseServiceImpl()
    
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
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    func configure() {
        self.setupFirebase()
    }
    
    func getUsers() -> DatabaseReference {
        return Database.database().reference().child("Users")
    }
    
    func getUserInDatabaseFrom(uid: String) -> DatabaseReference {
        return Database.database().reference().child("Users").child(uid)
    }
    
    func getCurrentUserUid() -> String? {
        return currentUser?.uid
    }
}

private extension FirebaseServiceImpl {
    func setupFirebase() {
        guard let options = firebaseOptions else { return }
        FirebaseApp.configure(options: options)
    }

    var firebaseOptions: FirebaseOptions? {
        guard let configFile = configFilePath else { return nil }
        return FirebaseOptions(contentsOfFile: configFile)
    }

    var configFilePath: String? {
        return Bundle.main.path(
            forResource: configurationFileName,
            ofType: Constants.configFileType
        )
    }
}

private extension FirebaseServiceImpl {
    var configurationFileName: String {
        return "GoogleService-Info"
    }

    enum Constants {
        static let configFileType = "plist"
    }
}

