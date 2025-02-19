import SwiftUI

struct TinderInitView: View {
    
    let openUsers: VoidClosure
    let cancel: VoidClosure
    
    let items: [(String, String)] = [
        ("icon_clock", "21:00-00:00h"),
        ("profile_pic", "Se verá su foto de perfil"),
        ("ticket", "Compre entrada para confirmar asistencia"),
        ("whisky_empty", "Confirma asistencia en el perfil del club.")
    ]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                
                HStack {
                    Button(action: {
                        cancel()
                    }) {
                        Image(systemName: "arrow.backward")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 32)
                .padding(.top, 42)
                
                Spacer()
                
                Image("brindis_social")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
//                    .padding(.top, 40)
                
                Text("¡Bienvenido a Social\nNightOut!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
//                    .padding(.horizontal)
                
                gridView
                    .transition(.opacity)
                
                Spacer()
                
                Button(action: {
                    openUsers()
                }) {
                    Text("Iniciar".uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.all, 10)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
       
    }
    
    var gridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 10) {
            ForEach(items, id: \.1) { item in
                TinderGridItemView(icon: item.0, text: item.1)
            }
        }
        .padding(8)
    }
}

struct TinderGridItemView: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .frame(height: 50)
            .background(Color.black)
            .padding(.horizontal)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(8)
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(Color.white)
        }
        .cornerRadius(8)
    }
}
