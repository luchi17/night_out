import SwiftUI

struct EventRow: View {
    let company: (CompanyModel, [Fiesta])
    let goToCompany: InputClosure<(CompanyModel, [Fiesta])>
    let goToEvent: InputClosure<(CompanyModel, Fiesta)>
    
    var body: some View {
        VStack {
            
            HStack(spacing: 10) {
                CircleImage(
                    imageUrl: company.0.imageUrl,
                    size: 60,
                    border: false
                )
                
                Text(company.0.username?.capitalized ?? "")
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
                    HStack(spacing: 0) {
                        ForEach(company.1, id: \.id) { fiesta in
                            HStack {
                                EventCardRow(
                                    fiesta: fiesta,
                                    imageWidth: 160,
                                    imageHeight: 250 - 16
                                )
                                .frame(width: 325, height: 250)
                                .onTapGesture {
                                    goToEvent((company.0, fiesta))
                                }
                                
                                Spacer()
                                    .frame(width: 14)
                            }
                        }
                    }
                    .padding([.vertical, .leading], 14)
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
    let imageHeight: CGFloat
    
    var body: some View {
        
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(Utils.formatDate(fiesta.fecha) ?? "Fecha")
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
                    .frame(width: imageWidth, height: imageHeight)
                    .clipped()
            } placeholder: {
                Color.grayColor
                    .scaledToFill()
                    .frame(width: imageWidth, height: imageHeight)
                    .clipped()
            }
            .padding([.vertical, .trailing], 8)
        }
        .background(Color.grayColor.opacity(0.2))
        .cornerRadius(8)
        .clipped()
    }
}

