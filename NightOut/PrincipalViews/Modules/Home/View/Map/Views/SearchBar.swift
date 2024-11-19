import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @State private var isEditing = false
    var onSearch: VoidClosure
    @Binding var forceUpdateView: Bool
    
    var body: some View {
        HStack {
            TextField("Search for...",
                      text: $searchText,
                      onEditingChanged: { focused in
                        self.isEditing = focused
                        self.forceUpdateView = false
                    },
                      onCommit: onSearch
            )
            .padding(7)
            .padding(.horizontal, 25)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
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
            .padding(.horizontal, 10)
            
            if isEditing {
                Button("Cancel") {
                    self.isEditing = false
                    self.searchText = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}
