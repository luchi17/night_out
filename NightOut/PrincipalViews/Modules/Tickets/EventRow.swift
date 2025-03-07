import SwiftUI

struct EventRow: View {
    let company: (CompanyModel, [Fiesta])
    let goToCompany: InputClosure<(CompanyModel, [Fiesta])>
    
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
                
                Text(">")
                    .foregroundColor(.white)
                
            }
            .onTapGesture {
                goToCompany(company)
            }
            
            if !company.1.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        if company.1.count == 1 {
                            Spacer() // Centra el único elemento
                            EventCardRow(
                                fiesta: company.1.first!,
                                imageWidth: 160
                            )
                            .frame(width: 325, height: 250)
                            Spacer()
                        } else {
                            ForEach(company.1, id: \.id) { fiesta in
                                EventCardRow(
                                    fiesta: fiesta,
                                    imageWidth: 160
                                )
                                .frame(width: 325, height: 250)
                            }
                        }
                    }
                    .padding(.all, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(Color.blackColor.opacity(0.2))
        .cornerRadius(10)
    }
}

struct EventCardRow: View {
    let fiesta: Fiesta
    let imageWidth: CGFloat
    
    var body: some View {
        
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(formatDate(fiesta.fecha) ?? "Fecha")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(fiesta.name.capitalized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                HStack(alignment: .top, spacing: 3) {
                    Text("⏰ Hora: ")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(fiesta.startTime) - \n\((fiesta.endTime))")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                Text("🎵 Música: \(fiesta.musicGenre)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
            
            Spacer()
            
            AsyncImage(url: URL(string: fiesta.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageWidth)
                    .clipped()
            } placeholder: {
                Color.grayColor
                    .scaledToFill()
                    .clipped()
            }
        }
        .background(Color.grayColor.opacity(0.2))
        .cornerRadius(10)
    }
    
    func formatDate(_ dateString: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd-MM-yyyy"
        inputFormatter.locale = Locale(identifier: "es_ES")

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d 'de' MMMM"
        outputFormatter.locale = Locale(identifier: "es_ES")

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return nil
    }
}

