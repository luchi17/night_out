import Combine
import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage

protocol LocationDatasource {
    func fetchCompanyLocations() -> AnyPublisher<CompanyUsersModel?, Never>
    func fetchAttendanceData() -> AnyPublisher<[String: Int], Never>
    
}

struct LocationDatasourceImpl: LocationDatasource {
    
    
#warning("Save in user defaults? where to call it?")
    func fetchCompanyLocations() -> AnyPublisher<CompanyUsersModel?, Never> {
        let publisher = PassthroughSubject<CompanyUsersModel?, Never>()
        
        let ref = FirebaseServiceImpl.shared.getCompanies()
        
        ref.getData { error, snapshot in
            
            guard error == nil else {
                print("Error fetching data: \(error!.localizedDescription)")
                publisher.send(nil)
                return
            }
            
            do {
                if let companies = try snapshot?.data(as: CompanyUsersModel.self) {
                    UserDefaults.setCompanies(companies)
                    publisher.send(companies)
                } else {
                    publisher.send(nil)
                }
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                publisher.send(nil)
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func fetchAttendanceData() -> AnyPublisher<[String: Int], Never> {
        
        let publisher = PassthroughSubject<[String: Int], Never>()
        
        let ref = FirebaseServiceImpl.shared.getAttendance()
        
        ref.getData { error, attendanceSnapshot in
            guard error == nil else {
                print("Error fetching data: \(error!.localizedDescription)")
                publisher.send([:])
                return
            }
            
            guard let children = attendanceSnapshot?.children else {
                publisher.send([:])
                return
            }
            
            var clubAttendanceMap = [String: Int]()
            for clubSnapshot in children {
                if let clubSnapshot = clubSnapshot as? DataSnapshot {
                    let clubId = clubSnapshot.key
                    let attendeesCount = Int(clubSnapshot.childrenCount)
                    clubAttendanceMap[clubId] = attendeesCount
                }
            }
            publisher.send(clubAttendanceMap)
        }
        return publisher.eraseToAnyPublisher()
    }
}
