import SwiftUI

struct RuletaView: View {
    @State private var names: [(String, Color)] = []
    @State private var newName: String = ""
    @State private var winner: String?
    
    var body: some View {
        VStack {
            TextField("Introduce un nombre", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Añadir Nombre") {
                if !newName.isEmpty {
                    let color = Color(
                        red: Double.random(in: 0...1),
                        green: Double.random(in: 0...1),
                        blue: Double.random(in: 0...1)
                    )
                    names.append((newName, color))
                    newName = ""
                }
            }
            .padding()
            
            RuletaSubview(names: $names) { winner in
                self.winner = winner
            }
            .padding()
            
            if let winner = winner {
                Text("¡El ganador es: \(winner)!").font(.largeTitle).padding()
            }
        }
        .padding()
    }
}

struct RuletaSubview: View {
    
    @Binding var names: [(String, Color)]
    @State private var currentAngle: Double = 0
    @State private var strokeWidth: Double = 3
    
    @State private var winnerIndex: Int? = nil
    
    var onResult: (String) -> Void
    
    let radius: CGFloat = 150

    var body: some View {
        VStack {
            ZStack {
                // Círculo de la ruleta
                Circle()
                    .fill(Color.gray)
                    .frame(width: 2 * radius, height: 2 * radius)
                    .overlay(Circle().stroke(Color.white, lineWidth: strokeWidth))
                
                if !names.isEmpty {
                    // Dibujar los segmentos de la ruleta
                    ForEach(0..<names.count, id: \.self) { index in
                        RouletteSegment(startAngle: angleForSegment(index),
                                        sweepAngle: angleForSegment(index + 1) - angleForSegment(index),
                                        color: names[index].1,
                                        radius: radius,
                                        name: names[index].0
                        )
                    }
                }
            }
            .frame(width: 2 * radius, height: 2 * radius)
            .padding(20)
            .rotationEffect(.degrees(currentAngle)) // Gira la ruleta toda
            
            Button("Girar Ruleta") {
                spin()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private func spin() {
        
        withAnimation(.easeInOut(duration: 3)) {
            currentAngle += 3600
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            winnerIndex = Int.random(in: 0..<names.count)
            onResult(names[winnerIndex ?? 0].0)
        }
    }
    
    // Cálculo del ángulo inicial para cada segmento
    func angleForSegment(_ index: Int) -> Double {
        return Double(index) * (360 / Double(names.count))
    }
}

struct RouletteSegment: View {
    var startAngle: Double
    var sweepAngle: Double
    var color: Color
    var radius: CGFloat
    var name: String
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: radius, y: radius)
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: Angle(degrees: startAngle), endAngle: Angle(degrees: startAngle + sweepAngle), clockwise: false)
        }
        .fill(color)
        .overlay(
            Text(name)
                .font(.headline)
                .foregroundColor(.white)
                .rotationEffect(.degrees(startAngle + sweepAngle / 2))
                .position(x: radius + radius * 0.6 * cos(CGFloat(startAngle + sweepAngle / 2) * .pi / 180),
                          y: radius + radius * 0.6 * sin(CGFloat(startAngle + sweepAngle / 2) * .pi / 180))
        )
    }
}
