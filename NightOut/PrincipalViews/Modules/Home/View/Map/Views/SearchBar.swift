import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @State private var isEditing = false
    var onSearch: VoidClosure
    
    var body: some View {
        HStack {
            TextField("Search for...",
                      text: $searchText,
                      onEditingChanged: { focused in
                        self.isEditing = focused
                    },
                      onCommit: onSearch
            )
            .autocorrectionDisabled()
            .padding(7)
            .padding(.horizontal, 25)
            .background(.gray.opacity(0.6))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                    
                    if isEditing {
                        Button(action: {
                            self.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
            )
            .padding(.horizontal, 12)
            
            if isEditing {
                Button("Cancel") {
                    self.isEditing = false
                    self.searchText = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
            }
        }
    }
}
