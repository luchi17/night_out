import SwiftUI

struct RuletaView: View {
    @State private var names: [(String, Color)] = []
    @State private var newName: String = ""
    @State private var spinning = false
    @State private var rotationAngle: Double = 0
    @State private var winner: String? = nil
    
    var body: some View {
        VStack {
            TextField("Introduce un nombre", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                
            Button("Añadir Nombre") {
                if !newName.isEmpty {
                    names.append((newName, Color.random()))
                    newName = ""
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            ScrollView {
                VStack {
                    ForEach(names, id: \.0) { name, color in
                        Text(name)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(color)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .frame(height: 200)
            
            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 3)
                    .frame(width: 300, height: 300)
                
                ForEach(0..<names.count, id: \.self) { index in
                    let angle = Angle(degrees: Double(index) * (360.0 / Double(names.count)))
                    Text(names[index].0)
                        .rotationEffect(-angle)
                        .position(x: 150 + cos(angle.radians) * 100, y: 150 + sin(angle.radians) * 100)
                }
                
                Triangle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .offset(y: -150)
                    .rotationEffect(.degrees(rotationAngle))
            }
            .rotationEffect(.degrees(rotationAngle))
            .animation(spinning ? .easeOut(duration: 3) : .default, value: rotationAngle)
            .padding()
            
            Button("Girar Ruleta") {
                if !names.isEmpty {
                    spinning = true
                    let randomIndex = Int.random(in: 0..<names.count)
                    let newAngle = Double.random(in: 1440...1800) + Double(randomIndex) * (360.0 / Double(names.count))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        winner = names[randomIndex].0
                        spinning = false
                    }
                    
                    rotationAngle += newAngle
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            if let winner = winner {
                Text("¡El ganador es: \(winner)!")
                    .font(.title)
                    .padding()
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension Color {
    static func random() -> Color {
        return Color(red: Double.random(in: 0...1),
                     green: Double.random(in: 0...1),
                     blue: Double.random(in: 0...1))
    }
}
