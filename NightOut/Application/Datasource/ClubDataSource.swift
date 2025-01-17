import Combine
import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage


protocol ClubDataSource {
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
    func removeAssistingToClub(clubId: String) -> AnyPublisher<Bool, Never>
    func addAssistingToClub(clubId: String, clubAssistance: ClubAssistance) -> AnyPublisher<Bool, Never>
}

struct ClubDataSourceImpl: ClubDataSource {

    // Observando cambios en firebase
    // equivalente: addValueEventListener en Android
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never> {
        
        let subject = CurrentValueSubject<[String: ClubAssistance], Never>([:])
        let ref = FirebaseServiceImpl.shared.getAssistance(profileId: profileId)
        
        ref.observe(.value) { snapshot in
            do {
                let assistance = try snapshot.data(as: [String: ClubAssistance].self)
                subject.send(assistance)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                subject.send([:])
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    func removeAssistingToClub(clubId: String) -> AnyPublisher<Bool, Never> {
        
        return Future<Bool, Never> { promise in
        
            guard let currentUserId = FirebaseServiceImpl.shared.currentUser?.uid else {
                promise(.success(false))
                return
            }
            
            let ref = FirebaseServiceImpl.shared
                .getAssistance(profileId: clubId)
                .child(currentUserId)
            
            ref.removeValue() { error, _ in
                if error == nil {
                    FirebaseServiceImpl.shared
                        .getUserInDatabaseFrom(uid: currentUserId)
                        .child("attendingClub")
                        .removeValue() { error, _ in
                            if error == nil {
                                promise(.success(true))
                            } else {
                                promise(.success(false))
                            }
                        }
                } else {
                    promise(.success(false))
                }
            }
            
        }
        .eraseToAnyPublisher()
    }
    
    func addAssistingToClub(clubId: String, clubAssistance: ClubAssistance) -> AnyPublisher<Bool, Never>{
        
        return Future<Bool, Never> { promise in
        
            guard let currentUserId = FirebaseServiceImpl.shared.currentUser?.uid else {
                promise(.success(false))
                return
            }
            
            let clubRef = FirebaseServiceImpl.shared
                .getAssistance(profileId: clubId)
                .child(currentUserId)
            
            clubRef.setValue(structToDictionary(clubAssistance)) { error, _ in
                if let error = error {
                    print("Error al guardar el usuario en asistencia del club: \(error.localizedDescription)")
                    promise(.success(false))
                } else {
                    print("Usuario guardado en asistencia al club")
                
                    FirebaseServiceImpl.shared
                        .getUserInDatabaseFrom(uid: currentUserId)
                        .child("attendingClub")
                        .setValue(clubId)
                    
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
   
}
