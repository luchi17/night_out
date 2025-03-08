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
            Text("\(entrada.price)€")
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
