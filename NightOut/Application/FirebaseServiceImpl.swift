import UIKit
import Firebase
import Foundation
import FirebaseAuth
import FirebaseDatabase
import SwiftUI

final class FirebaseServiceImpl: ObservableObject {
    static let shared = FirebaseServiceImpl()
    
    var isLoggedIn: Bool {
        return currentUser != nil
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
        return getUsers().child(uid)
    }
    
    func getCompanies() -> DatabaseReference {
        return Database.database().reference().child("Company_Users")
    }
    
    func getAttendance() -> DatabaseReference {
        return Database.database().reference().child("Attendance")
    }
    
    func getPosts() -> DatabaseReference {
        return Database.database().reference().child("Posts")
    }
    
    func getFollow() -> DatabaseReference {
        return Database.database().reference().child("Follow")
    }
    
    func getCompanyInDatabaseFrom(uid: String) -> DatabaseReference {
        return getCompanies().child(uid)
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

