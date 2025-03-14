import SwiftUI

struct LocationDetailSheet: View {
    var selectedLocation: LocationModel
    var openMaps: () -> Void
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    
                    if let imageUrl = selectedLocation.image {
                        
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipped()
                        } placeholder: {
                            ProgressView()
                                .frame(width: 150, height: 150)
                        }
                        .overlay(alignment: .topTrailing, content: {
                            Circle()
                                .fill(getStatusCircleColor())
                                .frame(width: 10, height: 10)
                                .offset(x: -5, y: 5)
                        })
                        .padding(.top, 15)
                        .padding(.bottom, 20)
                    
                    } else {
                        Color
                            .gray
                            .frame(width: 150, height: 150)
                            .overlay(alignment: .topTrailing, content: {
                                Circle()
                                    .fill(getStatusCircleColor())
                                    .frame(width: 10, height: 10)
                                    .offset(x: -5, y: 5)
                            })
                            .padding(.top, 15)
                            .padding(.bottom, 20)
                    }
                    
                    Text(selectedLocation.name)
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    if let endTime = selectedLocation.endTime,
                        let startTime = selectedLocation.startTime,
                        !endTime.isEmpty, !startTime.isEmpty {
                    
                        Text("Horario: \(startTime) - \(endTime)")
                            .font(.subheadline)
                            .padding(.bottom, 10)
                    } else {
                        Text("Horario desconocido")
                            .font(.subheadline)
                            .padding(.bottom, 10)
                    }
                    
                    if let selectedTag = selectedLocation.selectedTag, selectedLocation.selectedTag != LocationSelectedTag.none {
                        Text("Etiqueta: \(selectedTag.title)")
                            .font(.subheadline)
                            .padding(.bottom, 10)
                    }
                    
                    Text("Asistentes que conoces: \(String(describing: selectedLocation.followingGoing))")
                        .font(.subheadline)
                        .padding(.bottom, 10)
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            
            VStack {
                Button(action: {
                    openMaps()
                }) {
                    Text("Navegar a esta ubicación")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(25)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .padding()
        .presentationDetents([.height(300), .medium])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
    
    var placeholderImage: some View {
        Image("profile")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150)
            .cornerRadius(10)
            .padding(.vertical, 30)
    }
    
    func getStatusCircleColor() -> Color {
        
        guard let startTime = selectedLocation.startTime, let endTime = selectedLocation.endTime else {
            return .red
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let now = Date()
        let calendar = Calendar.current
        
        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else {
            return .red
        }
        
        let startDate = calendar.date(bySettingHour: calendar.component(.hour, from: start),
                                      minute: calendar.component(.minute, from: start),
                                      second: 0, of: now) ?? now
        
        let endDate = calendar.date(bySettingHour: calendar.component(.hour, from: end),
                                    minute: calendar.component(.minute, from: end),
                                    second: 0, of: now) ?? now
        
        return (now >= startDate && now <= endDate) ? .green : .red
        
    }
}
