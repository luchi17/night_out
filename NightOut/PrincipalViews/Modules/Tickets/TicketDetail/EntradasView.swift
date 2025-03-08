import SwiftUI


struct EntradasView: View {
    
    @Binding var entrada: Entrada
    
    var body: some View {
        
        HStack(alignment: .top) {
            VStack(spacing: 10) {
                Text(entrada.type)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(entrada.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            Text("\(String(describing: Double(String(format: "%.2f", entrada.price)) ?? 0.0 ))€")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .clipped()
        .padding()
        .background(Color.grayColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}



struct BuyTicketBottomSheet: View {
    @Binding var quantity: Int
    @Binding var precio: Double
    var precioInicial: Double
    var pagar: VoidClosure
    
    var body: some View {
        VStack(spacing: 20) {
        
            Spacer()
            
            HStack(spacing: 30) {
                Button(action: {
                    if quantity > 1 {
                        quantity -= 1
                        precio = precio / Double(quantity)
                    } else {
                        precio = precioInicial
                    }
                }) {
                    Text("-")
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(Color.white)
                        .foregroundColor(quantity > 1 ? Color.blackColor : .gray)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blackColor, lineWidth: 2))
                }
                .disabled(quantity == 1)
                
                
                ZStack {
                    Image(systemName: "trophy.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.blackColor)
                        .frame(width: 80, height: 80)

                    
                    Text("\(quantity)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .offset(y: -15) // Mueve el número arriba de la imagen
                }
                
                Button(action: {
                    quantity += 1
                    precio = precio * Double(quantity)
                }) {
                    Text("+")
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(Color.white)
                        .foregroundColor(Color.blackColor)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blackColor, lineWidth: 2))
                }
            }
            
            Spacer()
            
            Button(action: {
                pagar()
            }) {
                Text("PAGAR: \(String(describing: Double(String(format: "%.2f", precio)) ?? 0.0 ))€")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(Color.blackColor)
                    .cornerRadius(20)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}


struct WineGlassIcon: View {
    var body: some View {
        ZStack {
            // Base de la copa
            Path { path in
                path.move(to: CGPoint(x: 7, y: 21))
                path.addLine(to: CGPoint(x: 17, y: 21))
                path.addLine(to: CGPoint(x: 17, y: 23))
                path.addLine(to: CGPoint(x: 7, y: 23))
                path.closeSubpath()
            }
            .fill(Color.black)

            // Tallo de la copa
            Path { path in
                path.move(to: CGPoint(x: 11, y: 14))
                path.addLine(to: CGPoint(x: 11, y: 21))
                path.addLine(to: CGPoint(x: 13, y: 21))
                path.addLine(to: CGPoint(x: 13, y: 14))
                path.closeSubpath()
            }
            .fill(Color.black)

            // Cuerpo de la copa
            Path { path in
                path.move(to: CGPoint(x: 4, y: 3))
                path.addLine(to: CGPoint(x: 20, y: 3))
                path.addCurve(to: CGPoint(x: 15, y: 15), control1: CGPoint(x: 18, y: 7), control2: CGPoint(x: 15, y: 11))
                path.addCurve(to: CGPoint(x: 9, y: 15), control1: CGPoint(x: 15, y: 13), control2: CGPoint(x: 11, y: 13))
                path.addCurve(to: CGPoint(x: 4, y: 3), control1: CGPoint(x: 7, y: 11), control2: CGPoint(x: 4, y: 7))
                path.closeSubpath()
            }
            .fill(Color.black)
        }
        .frame(width: 50, height: 50)
    }
}
