import SwiftUI


struct IconsView: View {
    
    let emojis: [String] = ["copa1", "copa2", "copa3", "copa4", "copa5", "copa6", "copa7", "copa8"]
    var onEmojiSelected: InputClosure<String>
    
    var body: some View {
        VStack {
            Text("Puntúa en tu liga")
                .font(.system(size: 16))
                .foregroundColor(.black)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.leading, 12)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        onEmojiSelected(emoji)
                    } label: {
                        Image(emoji)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                    }
                }
            }
            .padding()
        }
    }
}
