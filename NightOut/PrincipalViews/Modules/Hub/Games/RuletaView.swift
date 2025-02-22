import SwiftUI

struct RuletaView: View {
    @State private var names: [(String, Color)] = []
    @State private var newName: String = ""
    @State private var winner: String?
    
    @State private var showInitIcon = false
    @State private var iconSize: CGFloat = 200
    @State private var iconOpacity = 1.0
    
    var body: some View {
        VStack {
            if let winner = winner {
                Text("¡El ganador es: \(winner)!").font(.largeTitle).padding()
                    .onAppear {
                        withAnimation(.easeIn(duration: 2)) {}
                        
                        // Mantener visible durante x segundos y luego desaparecer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                self.winner = nil
                                self.names = []
                                self.newName = ""
                            }
                        }
                    }
            } else {
                Image("ruleta")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .transition(.scale)
                
                TextField("", text: $newName, prompt: Text("Introduce un nombre...").foregroundColor(.white))
                    .foregroundColor(.white) // Color del texto
                    .accentColor(.white)
                    .padding()
                
                Button(action: {
                    if !newName.isEmpty {
                        let color = Color(
                            red: Double.random(in: 0...1),
                            green: Double.random(in: 0...1),
                            blue: Double.random(in: 0...1)
                        )
                        names.append((newName, color))
                        newName = ""
                    }
                }) {
                    Text("Añadir jugador".uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .padding()
                
                if !names.isEmpty {
                    RuletaSubview(names: $names) { winner in
                        self.winner = winner
                    }
                    .padding()
                } else {
                    Spacer()
                }
            }
        }
        .padding()
        .if(showInitIcon, transform: { view in
            initIconView
        })
        .onAppear {
            self.showInitIcon = true
        }
    }
    
    var initIconView: some View {
        Color.black
            .opacity(0.8)
            .edgesIgnoringSafeArea(.all)
            .overlay {
                Image("ruleta")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .opacity(iconOpacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                iconSize = 120
                                iconOpacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                showInitIcon = false
                            }
                        }
                    }
            }
    }
    
}

struct RuletaSubview: View {
    
    @Binding var names: [(String, Color)]
    @State private var currentAngle: Double = 0
    @State private var strokeWidth: Double = 1
    
    @State private var winnerIndex: Int? = nil
    
    @State var showNames: Bool = false
    
    var onResult: (String) -> Void
    
    let radius: CGFloat = 150

    var body: some View {
        VStack {
            ZStack {
                // Círculo de la ruleta
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 2 * radius, height: 2 * radius)
                    .overlay(Circle().stroke(Color.white, lineWidth: strokeWidth))
                
                if !names.isEmpty {
                    // Dibujar los segmentos de la ruleta
                    ForEach(0..<names.count, id: \.self) { index in
                        RouletteSegment(startAngle: angleForSegment(index),
                                        sweepAngle: angleForSegment(index + 1) - angleForSegment(index),
                                        color: names[index].1,
                                        radius: radius,
                                        name: names[index].0,
                                        showNames: showNames
                        )
                    }
                }
            }
            .frame(width: 2 * radius, height: 2 * radius)
            .padding(20)
            .rotationEffect(.degrees(currentAngle)) // Gira la ruleta toda
            
            Button(action: {
                spin()
            }) {
                Text("Girar Ruleta".uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding()
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
    var showNames: Bool
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: radius, y: radius)
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: Angle(degrees: startAngle), endAngle: Angle(degrees: startAngle + sweepAngle), clockwise: false)
        }
        .fill(color)
        .if(showNames, transform: { path in
            path
                .overlay {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(startAngle + sweepAngle / 2))
                        .position(x: radius + radius * 0.6 * cos(CGFloat(startAngle + sweepAngle / 2) * .pi / 180),
                                  y: radius + radius * 0.6 * sin(CGFloat(startAngle + sweepAngle / 2) * .pi / 180))
                }
        })
    }
}
