import UIKit
import Firebase
import Foundation

final class FirebaseServiceImpl {
    static let shared = FirebaseServiceImpl()

    func configure() {
        self.setupFirebase()
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

