import SwiftUI

struct EventRow: View {
    let company: (CompanyModel, [Fiesta])
    
    var body: some View {
        VStack {
            
            HStack(spacing: 10) {
                CircleImage(
                    imageUrl: company.0.imageUrl,
                    size: 60,
                    border: false
                )
                
                Text(company.0.username ?? "")
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            ScrollView(.horizontal) {
                
                HStack {
                    ForEach(company.1, id: \.id) { fiesta in
                        EventCardRow(
                            company: company.0,
                            fiesta: fiesta
                        )
                        .frame(width: 150, height: 150)
                    }
                }
            }
        }
        .padding()
        .background(Color.blackColor.opacity(0.2))
        .cornerRadius(10)
    }
}

struct EventCardRow: View {
    let company: CompanyModel
    let fiesta: Fiesta
    
    var body: some View {
        
        HStack {
            VStack {
                Text(fiesta.fecha)
                    .foregroundStyle(.blue)
                    .bold()
                Spacer()
                
                Text("Hora:")
                Text(fiesta.startTime)
                Text(fiesta.endTime)
                
                Text("Música: \(fiesta.musicGenre)")
            }
            
            AsyncImage(url: URL(string: fiesta.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } placeholder: {
                Color.grayColor
                    .scaledToFill()
                    .clipped()
            }
        }
    }
}

