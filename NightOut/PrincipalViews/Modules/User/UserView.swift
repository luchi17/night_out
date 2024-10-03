import SwiftUI

struct UserView: View {
    var body: some View {
        NavigationView {
                    VStack {
                        Text("User View")
//                        NavigationLink(destination: DetailView()) {
//                            Text("Go to Detail")
//                        }
                    }
                    .navigationTitle("User")
                }
    }
}


