import Combine
import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage


// UserGoingToClubAdapter add


protocol ClubDataSource {
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
}

struct ClubDataSourceImpl: ClubDataSource {

    // Observando cambios en firebase
    // equivalente: addValueEventListener en Android
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never> {
        
        let subject = CurrentValueSubject<[String: ClubAssistance], Never>([:])
        let ref = FirebaseServiceImpl.shared.getAssistance(profileId: profileId)
        
        ref.observe(.value) { snapshot in
            do {
                let users = try snapshot.data(as: [String: ClubAssistance].self)
                subject.send(users)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                subject.send([:])
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
   
}
