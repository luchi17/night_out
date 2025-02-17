import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct Level: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let progress: Double
}

class LevelsViewModel: ObservableObject {
    @Published var levelList: [Level] = []
    
    func loadUserLevels() {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let entriesRef =
        FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: currentUserId)
            .child("MisEntradas")
        
        entriesRef.observeSingleEvent(of: .value) { snapshot in
            let entryCount = Int(snapshot.childrenCount)
            
            DispatchQueue.main.async {
                self.levelList.removeAll()
                
                let level = self.calculateLevel(entryCount: entryCount)
                
                if entryCount == 0 {
                    self.levelList.append(Level(name: "Rookie Night", imageName: "nivel_1", progress: 0))
                } else {
                    self.levelList.append(level)
                }
            }
        } withCancel: { error in
            print("Error al cargar las entradas: \(error.localizedDescription)")
        }
    }
    
    private func calculateLevel(entryCount: Int) -> Level {
        let levelNumber = ((entryCount - 1) / 10) + 1 // Asegura que 0 entradas no sea Nivel 2
        let levelData: (String, String) = {
            switch levelNumber {
            case 1: return ("Nivel 1: Rookie Night", "nivel_1")
            case 2: return ("Nivel 2: Bar Explorer", "nivel_2")
            case 3: return ("Nivel 3: Dancefloor Starter", "nivel_3")
            case 4: return ("Nivel 4: Neon Challenger", "nivel_4")
            case 5: return ("Nivel 5: Beat Commander", "nivel_5")
            case 6: return ("Nivel 6: Club Royalty", "nivel_6")
            case 7: return ("Nivel 7: Party Legend", "nivel_7")
            case 8: return ("Nivel 8: Rave King/Queen", "nivel_8")
            case 9: return ("Nivel 9: Supreme VIP", "nivel_9")
            default: return ("Nivel 10: Boss of the Night", "nivel_10")
            }
        }()
        
        let progress = min((entryCount % 10) * 10, 100)
        return Level(name: levelData.0, imageName: levelData.1, progress: Double(progress))
    }
}

struct RookieLevelsView: View {
    
    @ObservedObject var viewModel: LevelsViewModel
        
        var body: some View {
            List(viewModel.levelList) { level in
                LevelRow(level: level)
            }
            .background(Color.clear)
            .scrollContentBackground(.hidden)
        }
}

struct LevelRow: View {
    let level: Level
    
    var body: some View {
        HStack {
            Image(level.imageName)
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(level.name)
                    .font(.headline)
                ProgressView(value: level.progress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            .padding(.leading, 8)
        }
        .padding()
    }
}
