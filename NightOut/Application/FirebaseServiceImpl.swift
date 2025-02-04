import UIKit
import Firebase
import Foundation
import FirebaseAuth
import FirebaseDatabase
import SwiftUI

final class FirebaseServiceImpl: ObservableObject {
    static let shared = FirebaseServiceImpl()
    
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
    
    func getClub() -> DatabaseReference {
        return Database.database().reference().child("Club")
    }
    
    func getAssistance(profileId: String) -> DatabaseReference {
        return getClub().child(profileId).child("Assistance")
    }
    
    func getPosts() -> DatabaseReference {
        return Database.database().reference().child("Posts")
    }
    
    func getFollow() -> DatabaseReference {
        return Database.database().reference().child("Follow")
    }
    
    func getComments() -> DatabaseReference {
        return Database.database().reference().child("Comments")
    }
    
    func getNotifications() -> DatabaseReference {
        return Database.database().reference().child("Notifications")
    }
    
    func getTerms() -> DatabaseReference {
        return Database.database().reference().child("Terms_Conditions")
    }
    
    func getLikedUsers(fromUid: String, toUid: String) -> DatabaseReference {
        return Database.database().reference().child("Users/\(fromUid)/Liked/\(toUid)")
    }
    
    func getChats(userUid: String, likedUserUid: String) -> DatabaseReference {
        return Database.database().reference().child("chats/\(userUid)/\(likedUserUid)")
    }
   
    func getCompanyInDatabaseFrom(uid: String) -> DatabaseReference {
        return getCompanies().child(uid)
    }
    
    func getCurrentUserUid() -> String? {
        return currentUser?.uid
    }
    
    func getIsLoggedin() -> Bool {
        guard currentUser != nil else {
            return false
        }
        let imUser = UserDefaults.getUserModel() != nil
        let imCompany = UserDefaults.getCompanyUserModel() != nil
        if imUser || imCompany {
            return true
        } else {
          return false
        }
    }
    
    func getImUser() -> Bool {
        return UserDefaults.getUserModel() != nil
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

