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
    func getClubName(profileId: String) -> AnyPublisher<String?, Never>
    
}

struct ClubDataSourceImpl: ClubDataSource {

    // Obtener el nombre del club al que el usuario está asistiendo
    func getClubName(profileId: String) -> AnyPublisher<String?, Never> {
        return Future<String?, Never> { promise in
            let ref = FirebaseServiceImpl.shared.getClub().child(profileId).child("name")
            
            ref.getData { error, snapshot in
                guard error == nil else {
                    print("Error fetching data: \(error!.localizedDescription)")
                    promise(.success(nil))
                    return
                }
                
                do {
                    if let name = try snapshot?.data(as: String.self) {
                        promise(.success(name))
                    } else {
                        promise(.success(nil))
                    }
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
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
