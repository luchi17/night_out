import SwiftUI

struct EventRow: View {
    let event: (CompanyModel, [Fiesta])
    
    var body: some View {
        HStack {
            Text(event.0.username ?? "")
                .foregroundColor(.white)
            
            ScrollView(.horizontal) {
                
                HStack {
                    ForEach(event.1) { fiesta in
                        Text(fiesta.fecha)
                            .foregroundColor(Color.grayColor)
                    }
                }
            }
        }
        .padding()
        .background(Color.grayColor.opacity(0.2))
        .cornerRadius(10)
    }
}

