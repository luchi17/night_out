import SwiftUI


struct CustomSellsAlertView: View {
    var title: String
    var options: [String]
    var onSelection: ([String]) -> Void
    var dismiss: VoidClosure
    
    @State private var selectedItems = Set<String>()
    @State private var showCompareView: Bool = false
    
    var body: some View {
        VStack {
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .padding(.top, 30)
                .padding(.bottom, 15)
            
            ScrollView {
                VStack {
                    ForEach(options, id: \.self) { item in
                        HStack(spacing: 15) {
                            
                            SellsCheckbox(isChecked: self.selectedItems.contains(item)) {
                                
                                if self.selectedItems.contains(item) {
                                    
                                    self.selectedItems.remove(item)
                                } else {
                                    
                                    self.selectedItems.insert(item)
                                }
                            }
                            
                            Text(item)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 20) {
                Spacer()
                
                Button(action: {
                    dismiss()
                    
                }) {
                    Text("Cancelar".uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.blue)
                }
                
                Button(action: {
                    onSelection(Array(selectedItems))
                    
                }) {
                    Text("Comparar".uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.blue)
                }
            }
            
        }
        .padding(.bottom, 40)
        .padding(.horizontal, 20)
        .background(Color.blackColor.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}

struct SellsCheckbox: View {
    var isChecked: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Fondo del checkbox
                if isChecked {
                    Color.blue // Fondo azul cuando está seleccionado
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    Color.clear // Sin fondo cuando no está seleccionado
                }
                
                // Borde blanco cuando no está seleccionado
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isChecked ? Color.clear : Color.white, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 5).fill(isChecked ? Color.blue : Color.clear))
                
                // Tic negro
                if isChecked {
                    Image(systemName: "checkmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color.blackColor) // Tic negro
                }
            }
            .frame(width: 24, height: 24) // Tamaño del checkbox
        }
    }
}

