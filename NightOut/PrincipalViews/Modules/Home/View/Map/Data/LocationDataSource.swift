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
    

//    var clubList: [Club] = []
    
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
                print("NO CHILDREN")
                publisher.send([:])
                return
            }
            print("------------")
            for snapshot in children {
                
                print(snapshot)
            }
            
            print("------------")
            
        }
//        ref.observeSingleEvent(of: .value) { snapshot in
//            var clubAttendanceMap = [String: Int]()
//            
//            for clubSnapshot in snapshot.children {
//                if let clubSnapshot = clubSnapshot as? DataSnapshot {
//                    let clubId = clubSnapshot.key
//                    let attendeesCount = Int(clubSnapshot.childrenCount)
//                    clubAttendanceMap[clubId] = attendeesCount
//                }
//            }
//            orderByAttendance(clubAttendanceMap)
//            
//        } withCancel: { error in
//            print("Error fetching data: \(error.localizedDescription)")
//        }
//        
        return publisher.eraseToAnyPublisher()
    }
    
//    func orderByAttendance(_ clubAttendanceMap: [String: Int]) {
//        clubList.sort { (club1, club2) -> Bool in
//            let attendance1 = clubAttendanceMap[club1.getUID()] ?? 0
//            let attendance2 = clubAttendanceMap[club2.getUID()] ?? 0
//            return attendance1 > attendance2
//        }
//    }


}
