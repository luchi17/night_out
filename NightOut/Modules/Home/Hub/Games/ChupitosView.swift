import SwiftUI


struct ChupitoWarsView: View {
    @State private var players: [String] = []
    @State private var currentPlayerIndex: Int = 0
    @State private var gameStarted: Bool = false
    @State private var currentQuestion: String = ""
    @State private var answer: String = ""
    
    @State private var userHasFailed: Bool = false
    @State private var playerName: String = ""
    
    @State private var showChupitoInitIcon = false
    @State private var iconSize: CGFloat = 200
    @State private var iconOpacity = 1.0
    
    @State private var toast: ToastType?
    
    @State private var lastItemInScrollId: UUID = UUID()
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        // Header Image
                        if let toast = toast {
                            ToastView(
                                type: toast,
                                onDismiss: {
                                    self.toast = nil
                                },
                                showCloseButton: false,
                                extraPadding: .none,
                                showTransition: false
                            )
                            .padding(.vertical, 0)
                            .frame(height: 60)
                        } else {
                            Spacer()
                                .frame(height: 65)
                        }
                        
                        VStack {
                            topView
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 20) {
                                if gameStarted {
                                    Text("Turno de: \(players[currentPlayerIndex])")
                                        .font(.system(size: 24, weight: .bold))
                                        .padding(.horizontal, 12)
                                    
                                    Text(currentQuestion)
                                        .font(.system(size: 20, weight: .bold))
                                        .padding(.horizontal, 12)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    
                                    TextField("", text: $answer, prompt: Text("Escribe tu respuesta").foregroundColor(.white))
                                        .onTapGesture {
                                             withAnimation {
                                                  proxy.scrollTo(lastItemInScrollId, anchor: .bottom)
                                             }
                                        }
                                        .foregroundColor(.white)
                                        .accentColor(.white)
                                        .padding(.horizontal, 12)
                                    
                                    submitButton
                                        .id(lastItemInScrollId)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                       
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .if(userHasFailed, transform: { view in
            
            ZStack(alignment: .top) {
                ChupitoView(showChupito: $userHasFailed)
                
                let correctAnswer = questionsAndAnswers.first(where: { $0.question == currentQuestion })?.answer.lowercased()
                ToastView(
                    type: .custom(.init(title: "", description: "Respuesta Correcta: \(correctAnswer ?? "")", image: nil)),
                    onDismiss: {
                        self.toast = nil
                        self.showRandomQuestion()
                    },
                    showCloseButton: false,
                    extraPadding: .none,
                    showTransition: false
                )
                .padding(.top, 0)
                .frame(height: 60)
            }
        })
        .if(showChupitoInitIcon, transform: { view in
            chupitoInitIconView
        })
        .onAppear {
            self.showChupitoInitIcon = true
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    
    var topView: some View {
        VStack {
            Image("chupitowar_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .transition(.scale)
            
            TextField("", text: $playerName, prompt: Text("Introduce un nombre...").foregroundColor(.white))
                .foregroundColor(.white) // Color del texto
                .accentColor(.white)
                .padding()
            
            Button(action: {
                addPlayer()
            }) {
                Text("Añadir jugador".uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.grayColor)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.top, 10)
            
            Button(action: {
                hideKeyboard()
                if gameStarted {
                    startGameAgain()
                } else {
                    startGame()
                }
               
            }) {
                Text(gameStarted ? "Empezar de nuevo".uppercased() : "Empezar juego".uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(gameStarted ? Color.grayColor : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.top, 10)
        }
    }
    
    var submitButton: some View {
        Button(action: {
            submitAnswer()
        }) {
            Text("Responder".uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color.grayColor)
                .cornerRadius(25)
        }
    }
    
    var chupitoInitIconView: some View {
        Color.blackColor
            .opacity(0.8)
            .edgesIgnoringSafeArea(.all)
            .overlay {
                Image("chupitowar_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .opacity(iconOpacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                iconSize = 80
                                iconOpacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                showChupitoInitIcon = false
                            }
                        }
                    }
            }
    }
    
    private func submitAnswer() {
        let userAnswer = answer.trimmingCharacters(in: .whitespaces).lowercased()
        let correctAnswer = questionsAndAnswers.first(where: { $0.question == currentQuestion })?.answer.lowercased()
        
        if correctAnswer != userAnswer { // Has fallado
            userHasFailed = true
        } else {
            showRandomQuestion()
        }
        
        answer = ""
        // Pasar turno al siguiente jugador
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }
    
    private func addPlayer() {
        let player = playerName.trimmingCharacters(in: .whitespaces)
        if !player.isEmpty && !players.contains(player) {
            players.append(playerName)
            toast = .success(.init(title: "", description: "\(playerName) añadido", image: nil))
        } else {
            toast = .custom(.init(title: "", description: "Nombre inválido o ya existente", image: nil))
        }
        playerName = ""
    }
    
    private func startGame() {
        if !players.isEmpty {
            gameStarted = true
            showRandomQuestion()
        } else {
            toast = .custom(.init(title: "", description: "Añade al menos un jugador para empezar", image: nil))
        }
    }
    
    private func startGameAgain() {
        gameStarted = false
        players = []
        playerName = ""
        answer = ""
        currentQuestion = ""
        currentPlayerIndex = 0
    }
    
    private func showRandomQuestion() {
        if let randomQuestion = questionsAndAnswers.randomElement() {
            currentQuestion = randomQuestion.question
        }
    }
    
    let questionsAndAnswers: [(question: String, answer: String)] = [
        ("¿Cuál es el país más pequeño del mundo?", "ciudad del vaticano"),
        ("¿En qué año llegó el hombre a la luna?", "1969"),
        ("¿Quién escribió Don Quijote de la Mancha?", "miguel de cervantes"),
        ("¿Cuál es el río más largo del mundo?", "amazonas"),
        ("¿Qué colores tiene la bandera de Francia?", "azul blanco rojo"),
        ("¿Quién pintó la Mona Lisa?", "leonardo da vinci"),
        ("¿Cuál es el idioma más hablado en el mundo?", "ingles"),
        ("¿En qué año comenzó la Segunda Guerra Mundial?", "1939"),
        ("¿Cuál es la capital de Japón?", "tokio"),
        ("¿Qué equipo de fútbol ha ganado más Champions League?", "real madrid"),
        ("¿Quién canta la canción 'Thriller'?", "michael jackson"),
        ("¿Cuál es el metal más caro del mundo?", "rodio"),
        ("¿Cuántos lados tiene un hexágono?", "6"),
        ("¿Cuál es el océano más grande del mundo?", "pacifico"),
        ("¿Quién descubrió la penicilina?", "alexander fleming"),
        ("¿En qué país se encuentra la Torre Eiffel?", "francia"),
        ("¿Cuál es el país con más población del mundo?", "china"),
        ("¿Cómo se llama la mascota amarilla de Pokémon?", "pikachu"),
        ("¿En qué año se estrenó la película Titanic?", "1997"),
        ("¿Qué grupo canta 'Bohemian Rhapsody'?", "queen"),
        ("¿Cuál es el planeta más grande del sistema solar?", "jupiter"),
        ("¿Qué continente tiene más países?", "africa"),
        ("¿En qué deporte se usa una raqueta y una pelota?", "tenis"),
        ("¿Qué animal es conocido como el 'rey de la selva'?", "leon"),
        ("¿Cuál es el símbolo químico del agua?", "h2o"),
        ("¿Cómo se llama el autor de 'Harry Potter'?", "jk rowling"),
        ("¿Cuál es la moneda oficial de Japón?", "yen"),
        ("¿Qué jugador de fútbol es conocido como 'La Pulga'?", "lionel messi"),
        ("¿Cuántos huesos tiene el cuerpo humano adulto?", "206"),
        ("¿En qué año terminó la Primera Guerra Mundial?", "1918"),
        ("¿Cuál es el idioma oficial de Brasil?", "portugues"),
        ("¿Qué instrumento toca Paco de Lucía?", "guitarra"),
        ("¿Cuál es la capital de Australia?", "canberra"),
        ("¿Qué serie tiene personajes como Arya Stark y Jon Snow?", "game of thrones"),
        ("¿Quién es el dios del trueno en la mitología nórdica?", "thor"),
        ("¿Qué deporte practica Serena Williams?", "tenis"),
        ("¿Qué gas respiramos principalmente?", "oxigeno"),
        ("¿Cuál es la montaña más alta del mundo?", "everest"),
        ("¿Quién canta 'Rolling in the Deep'?", "adele"),
        ("¿Cuántos anillos tiene el logo de los Juegos Olímpicos?", "5"),
        ("¿En qué país se inventó el sushi?", "japon"),
        ("¿Qué país ganó el Mundial de Fútbol en 2018?", "francia"),
        ("¿Cuál es el símbolo químico del oro?", "au"),
        ("¿Qué año marcó el fin de la Segunda Guerra Mundial?", "1945"),
        ("¿Qué artista pintó 'La última cena'?", "leonardo da vinci"),
        ("¿Cómo se llama el villano principal en 'Avengers: Endgame'?", "thanos"),
        ("¿Qué animal es el símbolo de WWF?", "panda"),
        ("¿Qué es más grande, un litro o un galón?", "galon"),
        ("¿Qué continente tiene más población?", "asia"),
        ("¿Cómo se llama el presidente de Estados Unidos en 2021?", "joe biden"),
        ("¿Qué animal es conocido como el mejor amigo del hombre?", "perro"),
        ("¿Qué país es famoso por la pizza y la pasta?", "italia"),
        ("¿Quién protagonizó la película 'Forrest Gump'?", "tom hanks"),
        ("¿Cuál es la raíz cuadrada de 64?", "8"),
        ("¿Qué fruta es conocida como el 'rey de las frutas'?", "mango"),
        ("¿En qué año se estrenó 'Breaking Bad'?", "2008"),
        ("¿Qué país ganó más medallas en los Juegos Olímpicos de Tokio 2020?", "estados unidos"),
        ("¿Qué animal puede regenerar partes de su cuerpo, como las estrellas de mar?", "estrella de mar"),
        ("¿Cuál es el tercer planeta desde el Sol?", "tierra"),
        ("¿En qué país se encuentra la Gran Muralla?", "china"),
        ("¿Qué artista es conocido como el Rey del Pop?", "michael jackson"),
        ("¿Qué videojuego tiene personajes como Mario y Luigi?", "super mario"),
        ("¿Qué tipo de animal es la ballena?", "mamifero"),
        ("¿En qué año comenzó la Revolución Francesa?", "1789"),
        ("¿Cuál es la velocidad de la luz en km/s?", "300000"),
        ("¿Qué serie tiene personajes como Walter White y Jesse Pinkman?", "breaking bad"),
        ("¿Quién inventó la bombilla?", "thomas edison"),
        ("¿Qué país tiene forma de bota?", "italia"),
        ("¿Qué deporte se juega con un bate y una pelota?", "beisbol"),
        ("¿En qué año se descubrió América?", "1492"),
        ("¿Cuál es la capital de Argentina?", "buenos aires"),
        ("¿Qué planeta es conocido como el planeta rojo?", "marte"),
        ("¿Quién escribió 'Cien años de soledad'?", "gabriel garcia marquez"),
        ("¿Qué superheroína lleva un lazo de la verdad?", "wonder woman"),
        ("¿Qué país produce más café en el mundo?", "brasil"),
        ("¿Qué animal tiene la lengua más larga en proporción a su cuerpo?", "camaleon"),
        ("¿Qué país ganó el primer Mundial de Fútbol en 1930?", "uruguay"),
        ("¿Cuál es el número atómico del hidrógeno?", "1"),
        ("¿En qué continente se encuentra Egipto?", "africa"),
        ("¿Qué artista es conocido por la canción 'Shape of You'?", "ed sheeran"),
        ("¿Cuál es el número de lados de un octágono?", "8"),
        ("¿Cómo se llama el director de la película 'Titanic'?", "james cameron"),
        ("¿Qué país es conocido por su cerveza Guinness?", "irlanda"),
        ("¿Qué órgano del cuerpo humano bombea sangre?", "corazon"),
        ("¿En qué país se originaron los Juegos Olímpicos?", "grecia"),
        ("¿Cuál es el nombre del fundador de Microsoft?", "bill gates"),
        ("¿Qué planeta tiene anillos visibles?", "saturno"),
        ("¿Quién fue el primer presidente de los Estados Unidos?", "george washington"),
        ("¿Qué serie incluye a los personajes Monica, Ross y Chandler?", "friends"),
        ("¿Qué metal se encuentra principalmente en el núcleo de la Tierra?", "hierro"),
        ("¿Cómo se llama la capital de México?", "ciudad de méxico"),
        ("¿Quién pintó 'El grito'?", "edvard munch"),
        ("¿Qué videojuego incluye el personaje Link?", "the legend of zelda"),
        ("¿Cuál es el océano más pequeño del mundo?", "artico"),
        ("¿Cómo se llama el fundador de Tesla y SpaceX?", "elon musk"),
        ("¿Qué instrumento musical tiene teclas blancas y negras?", "piano"),
        ("¿Cuál es el país con más volcanes activos?", "indonesia"),
        ("¿Qué mamífero tiene más fuerza relativa a su tamaño?", "hormiga"),
        ("¿Qué animal es conocido por dormir de pie?", "caballo"),
        ("¿En qué país se originó el flamenco?", "españa"),
        ("¿Quién es conocido como el Padre de la Física Moderna?", "albert einstein"),
        ("¿Qué país es famoso por su Torre Inclinada?", "italia"),
        ("¿Qué gas es el más abundante en la atmósfera terrestre?", "nitrogeno"),
        ("¿Qué poeta escribió 'La Divina Comedia'?", "dante alighieri"),
        ("¿Cuál es el deporte más popular del mundo?", "futbol"),
        ("¿Qué planeta tiene un día más largo que un año?", "venus"),
        ("¿Qué país inventó el origami?", "japon"),
        ("¿Cómo se llama el metal más ligero conocido?", "litio"),
        ("¿Qué banda británica lanzó el álbum 'Abbey Road'?", "the beatles"),
        ("¿En qué país se encuentra el Taj Mahal?", "india"),
        ("¿Qué continente alberga al río Amazonas?", "america del sur"),
        ("¿Qué escritor creó al personaje Sherlock Holmes?", "arthur conan doyle"),
        ("¿Cómo se llama la capital de Rusia?", "moscu"),
        ("¿Qué deporte incluye el término 'strike'?", "bolos"),
        ("¿Cuál es la estrella más cercana a la Tierra?", "sol"),
        ("¿Qué ciudad es conocida como la Gran Manzana?", "nueva york"),
        ("¿Qué tipo de animal es un ornitorrinco?", "mamifero"),
        ("¿Qué es un haiku?", "poema japones"),
        ("¿En qué país se encuentra el Desierto del Sahara?", "argelia"),
        ("¿Qué famosa saga de películas incluye un anillo mágico?", "el señor de los anillos"),
        ("¿Qué elemento químico tiene el símbolo Na?", "sodio"),
        ("¿Qué país tiene el mayor número de islas en el mundo?", "suecia"),
        ("¿Qué deporte se juega en Wimbledon?", "tenis"),
        ("¿Quién pintó la Capilla Sixtina?", "miguel angel"),
        ("¿Qué es el Monte Fuji?", "volcan"),
        ("¿Quién es conocido como el Rey del Reguetón?", "daddy yankee"),
        ("¿Cuál es el idioma oficial de Canadá junto con el inglés?", "frances"),
        ("¿Qué ave puede volar hacia atrás?", "colibri"),
        ("¿Cuál es el país más grande del mundo por área?", "rusia"),
        ("¿Qué escritor creó el mundo de 'Juego de Tronos'?", "george rr martin"),
        ("¿Qué máquina se usa para medir los terremotos?", "sismografo"),
        ("¿En qué país se encuentra Machu Picchu?", "peru"),
        ("¿Qué instrumento se utiliza para observar las estrellas?", "telescopio"),
        ("¿Qué gas llena los globos aerostáticos?", "helio"),
        ("¿Cómo se llama el dios del sol en la mitología egipcia?", "ra"),
        ("¿Qué es una galaxia?", "conjunto de estrellas"),
        ("¿Quién inventó el teléfono?", "alexander graham bell"),
        ("¿Cuál es el símbolo químico de la plata?", "ag"),
        ("¿Qué país es famoso por sus tulipanes y molinos de viento?", "paises bajos"),
        ("¿Qué ciudad alberga el Coliseo?", "roma"),
        ("¿Qué significa la sigla 'NASA'?", "administracion nacional de aeronautica y del espacio"),
        ("¿Qué órgano humano se encarga de filtrar la sangre?", "riñon"),
        ("¿Cuál es la capital de Alemania?", "berlín"),
        ("¿Cuál es la capital de Canadá?", "ottawa"),
        ("¿Cuál es la capital de Australia?", "canberra"),
        ("¿Cuál es la capital de Brasil?", "brasilia"),
        ("¿Cuál es la capital de Argentina?", "buenos aires"),
        ("¿Cuál es la capital de México?", "ciudad de méxico"),
        ("¿Cuál es la capital de Italia?", "roma"),
        ("¿Cuál es la capital de Rusia?", "moscú"),
        ("¿Cuál es la capital de China?", "pekín"),
        ("¿Cuál es la capital de India?", "nueva delhi"),
        ("¿Cuál es la capital de Egipto?", "el cairo"),
        ("¿Cuál es la capital de Sudáfrica?", "pretoria"),
        ("¿Cuál es la capital de Turquía?", "ankara"),
        ("¿Cuál es la capital de España?", "madrid"),
        ("¿Cuál es la capital de Noruega?", "oslo"),
        ("¿Cuál es la capital de Suecia?", "estocolmo"),
        ("¿Cuál es la capital de Finlandia?", "helsinki"),
        ("¿Cuál es la capital de Corea del Sur?", "seúl"),
        ("¿Cuál es la capital de Corea del Norte?", "pyongyang"),
        ("¿Cuál es la capital de Arabia Saudita?", "riad"),
        ("¿Cuál es el océano más grande del mundo?", "pacífico"),
        ("¿Cuál es el desierto más grande del mundo?", "antártico"),
        ("¿En qué continente se encuentra el desierto del Sahara?", "áfrica"),
        ("¿Cuál es el país más grande del mundo?", "rusia"),
        ("¿Cuál es el país más pequeño del mundo?", "ciudad del vaticano"),
        ("¿Cuál es la montaña más alta del mundo?", "everest"),
        ("¿Qué mar separa a Europa de África?", "mediterráneo"),
        ("¿Cuál es el río más largo del mundo?", "amazonas"),
        ("¿Cuál es el lago más grande del mundo?", "mar caspio"),
        ("¿Qué país tiene más islas en el mundo?", "suecia"),
        ("¿Cuál es el punto más profundo de los océanos?", "fosa de las marianas"),
        ("¿Qué país es conocido como la Tierra del Sol Naciente?", "japón"),
        ("¿En qué país se encuentra la Torre de Pisa?", "italia"),
        ("¿Cuál es la isla más grande del mundo?", "groenlandia"),
        ("¿Cuántos continentes hay en el mundo?", "7"),
        ("¿Cuál es el país más poblado del mundo?", "china"),
        ("¿Cuál es el segundo país más grande del mundo en territorio?", "canadá"),
        ("¿Cuál es el único país que es también un continente?", "australia"),
        ("¿Qué separa América del Norte de América del Sur?", "canal de panamá"),
        // Historia
        ("¿En qué año terminó la Segunda Guerra Mundial?", "1945"),
        ("¿Quién fue el primer presidente de Estados Unidos?", "george washington"),
        ("¿En qué año comenzó la Revolución Francesa?", "1789"),
        ("¿Quién fue el líder del Imperio Romano cuando nació Jesucristo?", "augusto"),
        ("¿Cuál fue la primera civilización de la historia?", "sumerios"),
        ("¿Quién descubrió América?", "cristóbal colón"),
        ("¿En qué año se firmó la Declaración de Independencia de Estados Unidos?", "1776"),
        ("¿Quién fue el faraón más famoso de Egipto?", "tutankamón"),
        ("¿Quién fue el emperador de Francia en 1804?", "napoleón bonaparte"),
        ("¿En qué año cayó el Muro de Berlín?", "1989"),
        ("¿Quién fue el último zar de Rusia?", "nicolás ii"),
        ("¿Cuál fue el conflicto que dividió a EE.UU. en el siglo XIX?", "guerra civil"),
        ("¿Qué país lanzó la primera bomba atómica en la Segunda Guerra Mundial?", "estados unidos"),
        ("¿Cuál fue la primera dinastía china?", "xia"),
        ("¿En qué año terminó la Primera Guerra Mundial?", "1918"),
        ("¿Quién escribió el Manifiesto Comunista?", "karl marx"),
        ("¿En qué año cayó el Imperio Romano de Occidente?", "476"),
        ("¿Quién descubrió América?", "cristóbal colón"),
        ("¿Qué guerra se libró entre 1914 y 1918?", "primera guerra mundial"),
        ("¿Qué tratado puso fin a la Primera Guerra Mundial?", "tratado de versalles"),
        ("¿En qué año terminó la Segunda Guerra Mundial?", "1945"),
        ("¿Qué país fue el primero en enviar un hombre a la Luna?", "estados unidos"),
        ("¿Cómo se llamaba el primer emperador de Roma?", "augusto"),
        ("¿Qué civilización construyó Machu Picchu?", "inca"),
        ("¿Quién fue el líder de la Revolución Cubana en 1959?", "fidel castro"),
        ("¿Qué cayó en 1989 simbolizando el fin de la Guerra Fría?", "muro de berlín"),
        // Deportes
        ("¿Cuántos jugadores tiene un equipo de fútbol en el campo?", "11"),
        ("¿En qué deporte se usa un bate y una pelota?", "béisbol"),
        ("¿Cuál es el evento deportivo más importante del mundo?", "juegos olímpicos"),
        ("¿Qué país ganó la Copa Mundial de la FIFA en 2018?", "francia"),
        ("¿Cuántos tiempos tiene un partido de baloncesto?", "4"),
        ("¿Quién es considerado el mejor futbolista de todos los tiempos?", "pelé"),
        ("¿Cuál es el país con más títulos de la Copa del Mundo?", "brasil"),
        ("¿Cuántos aros tiene el logo de los Juegos Olímpicos?", "5"),
        ("¿Qué deporte se juega en Wimbledon?", "tenis"),
        ("¿Cuántos puntos vale un triple en baloncesto?", "3"),
        ("¿Quién es el máximo goleador en la historia de los mundiales?", "miroslav klose"),
        ("¿Qué país es famoso por las corridas de toros?", "españa"),
        ("¿Qué equipo de la NBA ha ganado más campeonatos?", "boston celtics"),
        ("¿En qué ciudad se celebraron los primeros Juegos Olímpicos modernos?", "atenas"),
        ("¿Cuál es el deporte más practicado en el mundo?", "fútbol"),
        ("¿Qué jugador de baloncesto es conocido como 'Air Jordan'?", "michael jordan"),
        ("¿Quién es el piloto con más títulos de Fórmula 1?", "lewis hamilton"),
        ("¿Qué equipo de fútbol ha ganado más Champions League?", "real madrid"),
        ("¿En qué país se encuentra el Gran Cañón?", "estados unidos"),
        ("¿Cuál es la capital de Australia?", "canberra"),
        ("¿Qué país tiene forma de bota?", "italia"),
        ("¿Qué país sudamericano no tiene costa?", "bolivia"),
        ("¿Qué cordillera separa Europa de Asia?", "montes urales"),
        ("¿Cuál es el golfo más grande del mundo?", "golfo de méxico"),
        ("¿Cuál es la capital de Sudáfrica?", "pretoria"),
        ("¿Cuáles son los únicos dos países sin frontera terrestre?", "australia y nueva zelanda"),
        ("¿Cuál es el país con más volcanes activos?", "indonesia"),
        ("¿En qué océano se encuentra Madagascar?", "índico"),
        // Cultura General
        ("¿Cuántos planetas hay en el Sistema Solar?", "8"),
        ("¿Quién escribió 'Don Quijote de la Mancha'?", "miguel de cervantes"),
        ("¿Cuál es el metal más abundante en la corteza terrestre?", "aluminio"),
        ("¿En qué año se fundó Google?", "1998"),
        ("¿Qué animal es el símbolo de la paz?", "paloma"),
        ("¿Cuántos lados tiene un hexágono?", "6"),
        ("¿Qué famoso científico desarrolló la teoría de la relatividad?", "albert einstein"),
        ("¿Cuánto dura un año en Júpiter en comparación con la Tierra?", "12 años"),
        ("¿Cuál es el idioma más hablado en el mundo?", "inglés"),
        ("¿Qué instrumento musical tiene teclas blancas y negras?", "piano"),
        // Política
        ("¿Cuántos países forman parte de la ONU?", "193"),
        ("¿Quién fue el primer presidente de la Unión Soviética?", "vladímir lenin"),
        ("¿Qué país tiene la democracia más antigua del mundo?", "grecia"),
        ("¿Cuántos senadores hay en el Senado de Estados Unidos?", "100"),
        ("¿En qué país nació el comunismo?", "alemania"),
        ("¿Quién es considerado el padre del liberalismo?", "john locke"),
        ("¿En qué año se firmó el Tratado de Versalles?", "1919"),
        ("¿Cuál es el partido político más antiguo del mundo?", "partido demócrata"),
        ("¿Qué presidente de EE.UU. abolió la esclavitud?", "abraham lincoln"),
        ("¿Cuántos estados tiene EE.UU.?", "50")
        
    ]
}

import SwiftUI

struct ChupitoView: View {
    
    @Binding var showChupito: Bool
    
    var body: some View {
        ZStack {
            // Fondo semi-transparente
            if showChupito {
                Color.blackColor.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .zIndex(1)
                
                Image("chupito_image")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 250)
                    .opacity(showChupito ? 1 : 0)
                    .transition(.opacity)
                    .zIndex(2)
                    .onAppear {
                        withAnimation(.easeIn(duration: 2)) {
                            self.showChupito = true
                        }
                        
                        // Mantener visible durante x segundos y luego desaparecer
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                self.showChupito = false
                            }
                        }
                    }
            }
        }
    }
}
