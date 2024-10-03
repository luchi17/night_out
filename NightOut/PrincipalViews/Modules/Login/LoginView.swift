import SwiftUI

struct LoginView: View, Hashable {
    
    public let id = UUID()
    
    static func == (lhs: LoginView, rhs: LoginView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Combina el id para el hash
    }
    
    
    var body: some View {
        VStack {
            Text("Login View")
//                        NavigationLink(destination: DetailView()) {
//                            Text("Go to Detail")
//                        }
        }
    }
}


