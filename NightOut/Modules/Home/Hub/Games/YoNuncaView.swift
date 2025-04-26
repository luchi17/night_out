import SwiftUI

struct YoNuncaView: View {
    @State private var yoNuncaText: String = ""

    var body: some View {
        VStack {
            Text(yoNuncaText)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .padding()

            Button(action: {
                showRandomYoNunca()
            }) {
                Text("Otro yo nunca".uppercased())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.grayColor)
                    .cornerRadius(25)
            }
            .padding()
        }
        .onAppear {
            showRandomYoNunca()
        }
    }
    
    private func showRandomYoNunca() {
        // Seleccionar un "Yo Nunca" aleatorio
        yoNuncaText = "\(yoNunca.randomElement() ?? "")"
    }
    
    let yoNunca: [String] = [
        "Yo nunca he besado a alguien del mismo sexo.",
        "Yo nunca he mandado un mensaje subido de tono.",
        "Yo nunca he fingido un orgasmo.",
        "Yo nunca he hecho un striptease.",
        "Yo nunca he tenido un sueño erótico con alguien presente en esta habitación.",
        "Yo nunca he practicado sexting.",
        "Yo nunca he usado un juguete sexual.",
        "Yo nunca he tenido una cita a ciegas.",
        "Yo nunca he coqueteado con el amigo/a de mi pareja.",
        "Yo nunca he enviado una foto comprometedora.",
        "Yo nunca he usado aplicaciones de citas.",
        "Yo nunca he tenido una aventura de una noche.",
        "Yo nunca he besado a dos personas diferentes en un día.",
        "Yo nunca he tenido un crush con un profesor/a.",
        "Yo nunca he visto porno.",
        "Yo nunca he hecho un trío.",
        "Yo nunca he tenido relaciones en un lugar público.",
        "Yo nunca he besado a alguien sin recordar su nombre.",
        "Yo nunca he espiado el teléfono de mi pareja.",
        "Yo nunca he sentido celos de un ex de mi pareja.",
        "Yo nunca he dicho 'te amo' sin sentirlo de verdad.",
        "Yo nunca he tenido una fantasía con alguien de esta habitación.",
        "Yo nunca he mentido sobre mi experiencia sexual.",
        "Yo nunca he tenido una relación abierta.",
        "Yo nunca he usado ropa interior atrevida para impresionar.",
        "Yo nunca he coqueteado con un desconocido/a en un bar.",
        "Yo nunca he mandado un mensaje a mi ex estando borracho/a.",
        "Yo nunca he tenido un sueño erótico con mi jefe/a.",
        "Yo nunca he probado una posición sexual extraña.",
        "Yo nunca he hablado sucio durante el sexo.",
        "Yo nunca he sido atrapado/a en el acto.",
        "Yo nunca he mentido para salir de una cita.",
        "Yo nunca he dejado en visto un mensaje importante de mi pareja.",
        "Yo nunca he enviado una foto atrevida por error.",
        "Yo nunca he tenido relaciones en una casa ajena.",
        "Yo nunca he probado un disfraz para algo más que Halloween.",
        "Yo nunca he besado a alguien en un ascensor.",
        "Yo nunca he utilizado esposas en la intimidad.",
        "Yo nunca he tenido sexo en la playa.",
        "Yo nunca he hecho el primer movimiento.",
        "Yo nunca he jugado un juego de beber atrevido.",
        "Yo nunca he sido rechazado/a por alguien que me gustaba.",
        "Yo nunca he fingido que no me importaba cuando realmente me dolió.",
        "Yo nunca he compartido una fantasía sexual con alguien.",
        "Yo nunca he hecho un baile privado para alguien.",
        "Yo nunca he tenido una relación secreta.",
        "Yo nunca he mentido sobre mi soltería.",
        "Yo nunca he usado mi encanto para obtener algo.",
        "Yo nunca he tenido una experiencia íntima inesperada.",
        "Yo nunca he robado un beso.",
        "Yo nunca he dicho algo inapropiado por accidente en público.",
        "Yo nunca he participado en un juego de roles.",
        "Yo nunca he tenido sexo en un coche.",
        "Yo nunca he besado a alguien que acababa de conocer.",
        "Yo nunca he tenido una cita incómoda.",
        "Yo nunca he tenido una conversación íntima por teléfono.",
        "Yo nunca he tenido un encuentro con alguien que apenas conocía.",
        "Yo nunca he probado el slow dance sin música.",
        "Yo nunca he sido infiel en una relación.",
        "Yo nunca he sentido algo por alguien comprometido.",
        "Yo nunca he besado a alguien mayor que yo por más de 10 años.",
        "Yo nunca he hablado de mis fetiches abiertamente.",
        "Yo nunca he usado la excusa del trabajo para evitar a alguien.",
        "Yo nunca he tenido un encuentro romántico en un lugar inesperado.",
        "Yo nunca he participado en un strip poker.",
        "Yo nunca he dejado de hablar con alguien porque me rechazó.",
        "Yo nunca he tenido una conexión emocional en una noche.",
        "Yo nunca he tenido un crush con alguien presente en esta habitación.",
        "Yo nunca he hablado mal de alguien en esta sala sin que lo supiera.",
        "Yo nunca he sentido celos de alguien aquí.",
        "Yo nunca he dicho algo vergonzoso frente a alguien en este grupo.",
        "Yo nunca he pensado que alguien aquí está demasiado bien vestido.",
        "Yo nunca he stalkeado a alguien presente en esta sala en redes sociales.",
        "Yo nunca he mentido para no salir con alguien aquí.",
        "Yo nunca he enviado un mensaje sobre alguien de aquí al grupo equivocado.",
        "Yo nunca me he reído de alguien en esta habitación sin que lo supiera.",
        "Yo nunca he compartido un secreto de alguien de este grupo sin permiso.",
        "Yo nunca he fingido estar de acuerdo con alguien de aquí para evitar problemas.",
        "Yo nunca he pensado que alguien aquí era molesto/a en algún momento.",
        "Yo nunca he hecho algo extraño para impresionar a alguien de este grupo.",
        "Yo nunca he estado enojado/a con alguien presente aquí y no se lo he dicho.",
        "Yo nunca he contado un chisme sobre alguien en esta sala.",
        "Yo nunca he pensado que alguien aquí estaba mintiendo en este juego.",
        "Yo nunca he compartido una foto o publicación de alguien aquí sin que lo supiera.",
        "Yo nunca he sentido vergüenza por algo que alguien aquí hizo.",
        "Yo nunca he ignorado un mensaje de alguien en este grupo a propósito.",
        "Yo nunca he sentido envidia de algo que tiene alguien presente aquí.",
        "Yo nunca he evitado saludar a alguien aquí en público.",
        "Yo nunca he jugado mal a propósito para que alguien aquí ganara.",
        "Yo nunca he hecho una promesa a alguien aquí que no cumplí.",
        "Yo nunca he intentado hacer reír a alguien de aquí y he fallado.",
        "Yo nunca he tenido una discusión con alguien aquí por algo ridículo.",
        "Yo nunca he hecho algo atrevido en un baño público.",
        "Yo nunca he dejado mi ropa interior en la casa de alguien.",
        "Yo nunca he coqueteado con alguien sabiendo que estaba comprometido/a.",
        "Yo nunca he hecho algo atrevido en un avión.",
        "Yo nunca he sentido atracción por un amigo/a cercano/a.",
        "Yo nunca he leído mensajes privados de mi pareja sin permiso.",
        "Yo nunca he probado comida en el cuerpo de alguien.",
        "Yo nunca he tenido relaciones con alguien cuyo nombre no recuerdo.",
        "Yo nunca he enviado un mensaje atrevido por error a un grupo.",
        "Yo nunca he tenido una cita por pura curiosidad.",
        "Yo nunca he sentido culpa después de un encuentro íntimo.",
        "Yo nunca he recibido una propuesta indecente de un desconocido/a.",
        "Yo nunca he dejado a alguien por una razón superficial.",
        "Yo nunca he tenido relaciones con alguien del trabajo.",
        "Yo nunca he utilizado frases cliché para ligar.",
        "Yo nunca he buscado a alguien solo por atracción física.",
        "Yo nunca he hablado mal de mi pareja actual o pasada.",
        "Yo nunca he dejado que alguien se aprovechara de mí emocionalmente.",
        "Yo nunca he tenido fantasías con una celebridad.",
        "Yo nunca he mentido sobre mi número de parejas.",
        "Yo nunca he sentido vergüenza por lo que hice la noche anterior.",
        "Yo nunca he probado algo atrevido inspirado en una película o serie."
    ]
}
