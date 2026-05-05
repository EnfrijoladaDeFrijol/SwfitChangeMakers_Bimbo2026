import SwiftUI
import Combine

// MARK: - RestockItem
struct RestockItem: Identifiable {
    let id        = UUID()
    let productoId: String
    var nombre:     String
    var cantidad:   Int
    var esQuita:    Bool   // true = reducir stock, false = agregar
    var imagenAsset: String = ""
}

// MARK: - VoiceAssistantViewModel
@MainActor
final class VoiceAssistantViewModel: ObservableObject {

    // Estado publicado para la UI
    @Published var isRecording:    Bool         = false
    @Published var transcribedText:String       = ""
    @Published var items:          [RestockItem] = []
    @Published var bimboMessage:   String       = ""
    @Published var showSuccess:    Bool         = false
    @Published var permisosOK:     Bool         = false
    @Published var simulandoVoz:   Bool         = false

    let voice = VoiceRecognitionService()
    private let catalogo: [Producto]
    private var cancellables = Set<AnyCancellable>()
    private var simTimer: Timer?

    /// Tienda asociada (contextual)
    let tiendaNombre: String
    /// Modo quitar por defecto
    let modoQuitar: Bool

    // Frases de simulación para demo
    private let frasesSimulacionAgregar = [
        "agrega 5 gansitos y 3 donitas",
        "mete 10 pan blanco y 6 nitos",
        "pon 4 roles de canela y 8 bimbollos",
        "dale 3 pingüinos y 5 gansitos",
        "suma 7 donitas y 2 nitos",
    ]
    private let frasesSimulacionQuitar = [
        "quita 3 gansitos y 2 donitas",
        "retira 5 pan blanco y 4 nitos",
        "baja 2 roles de canela y 3 bimbollos",
        "saca 4 pingüinos y 1 gansito",
    ]

    // Mensajes con personalidad Bimbo
    private let mensajesInicio = [
        "¡Listo! Habla cuando quieras.",
        "¡Órale! Dime qué lleva la tienda.",
        "¡Aquí estoy! Cuéntame.",
        "¡Ándale! ¿Qué productos van?"
    ]
    private let mensajesExito = [
        "¡Sale y vale! 🎉",
        "¡Chido! Ya lo apunté.",
        "¡Listo! Verifica y ajusta.",
        "¡Eso mero! Revisa cantidades."
    ]
    private let mensajesError = [
        "No te entendí, ¿me lo repites?",
        "Habla un poco más fuerte.",
        "No escuché producto. Intenta de nuevo."
    ]

    init(tiendaNombre: String = "", modoQuitar: Bool = false, catalogo: [Producto] = Producto.mockCatalogo) {
        self.tiendaNombre = tiendaNombre
        self.modoQuitar   = modoQuitar
        self.catalogo     = catalogo
        self.bimboMessage = modoQuitar
            ? "¿Qué producto retiramos?"
            : "¿Qué producto ingresamos?"
        suscribirse()
    }

    // MARK: Suscripciones
    private func suscribirse() {
        voice.$transcripcion
            .receive(on: DispatchQueue.main)
            .sink { [weak self] texto in
                guard let self, !self.simulandoVoz else { return }
                self.transcribedText = texto
            }
            .store(in: &cancellables)

        voice.$isGrabando
            .receive(on: DispatchQueue.main)
            .sink { [weak self] grabando in
                guard let self, !self.simulandoVoz else { return }
                self.isRecording = grabando
            }
            .store(in: &cancellables)
    }

    // MARK: Control de grabación
    func toggleGrabacion() {
        if isRecording || simulandoVoz {
            detener()
        } else {
            iniciar()
        }
    }

    func iniciar() {
        items.removeAll()
        transcribedText = ""
        bimboMessage = mensajesInicio.randomElement() ?? mensajesInicio[0]

        // Intentar micrófono real primero
        if permisosOK {
            voice.iniciarGrabacion()
            isRecording = true

            // Fallback: si después de 4 segundos no hay transcripción, simular
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                guard let self, self.isRecording, self.transcribedText.isEmpty else { return }
                self.voice.detenerGrabacion()
                self.iniciarSimulacion()
            }
        } else {
            // Sin permisos → ir directo a simulación
            iniciarSimulacion()
        }
    }

    func detener() {
        simTimer?.invalidate()
        simTimer = nil

        if simulandoVoz {
            simulandoVoz = false
            isRecording = false
            procesarTranscripcion(transcribedText)
        } else {
            voice.detenerGrabacion()
            isRecording = false
            procesarTranscripcion(transcribedText)
        }
    }

    // MARK: - Simulación de voz (para demo)
    private func iniciarSimulacion() {
        simulandoVoz = true
        isRecording  = true

        let frases = modoQuitar ? frasesSimulacionQuitar : frasesSimulacionAgregar
        let frase  = frases.randomElement() ?? frases[0]
        let palabras = frase.components(separatedBy: " ")

        transcribedText = ""
        var index = 0

        // Simula escritura palabra por palabra
        simTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            Task { @MainActor in
                if index < palabras.count {
                    self.transcribedText += (index == 0 ? "" : " ") + palabras[index]
                    index += 1
                } else {
                    timer.invalidate()
                    // Auto-detener después de completar la frase
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.detener()
                    }
                }
            }
        }
    }

    func solicitarPermisos() async {
        permisosOK = await voice.solicitarPermisos()
        if !permisosOK {
            bimboMessage = modoQuitar
                ? "¿Qué producto retiramos?"
                : "¿Qué producto ingresamos?"
        }
    }

    // MARK: Ajuste manual (HCAI override)
    func incrementar(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].cantidad += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func decrementar(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].cantidad = max(0, items[idx].cantidad - 1)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func eliminar(id: UUID) {
        items.removeAll { $0.id == id }
    }

    func limpiarLista() {
        items.removeAll()
        transcribedText = ""
        bimboMessage = modoQuitar
            ? "¿Qué producto retiramos?"
            : "¿Qué producto ingresamos?"
    }

    func confirmarPedido() {
        showSuccess = true
        bimboMessage = "¡Pedido confirmado!"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - NLP On-device (español)
    private func procesarTranscripcion(_ texto: String) {
        guard !texto.trimmingCharacters(in: .whitespaces).isEmpty else {
            bimboMessage = mensajesError.randomElement() ?? mensajesError[0]
            return
        }

        let nuevos = parsearComando(texto)
        if nuevos.isEmpty {
            bimboMessage = mensajesError.randomElement() ?? mensajesError[0]
        } else {
            for nuevo in nuevos {
                if let idx = items.firstIndex(where: { $0.productoId == nuevo.productoId }) {
                    items[idx].cantidad += nuevo.esQuita ? -nuevo.cantidad : nuevo.cantidad
                    items[idx].cantidad = max(0, items[idx].cantidad)
                } else {
                    items.append(nuevo)
                }
            }
            bimboMessage = mensajesExito.randomElement() ?? mensajesExito[0]
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Parser NLP básico
    private func parsearComando(_ texto: String) -> [RestockItem] {
        let lower = texto.lowercased()
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ú", with: "u")
            .replacingOccurrences(of: "ü", with: "u")

        let textoEsQuita = verbosQuita.contains(where: { lower.contains($0) })
        let textoEsAgrega = verbosAgrega.contains(where: { lower.contains($0) })
        let esQuita: Bool
        if textoEsQuita && !textoEsAgrega {
            esQuita = true
        } else if textoEsAgrega && !textoEsQuita {
            esQuita = false
        } else {
            esQuita = modoQuitar
        }

        var resultado: [RestockItem] = []

        for producto in catalogo {
            let alias = aliasProducto(producto)
            guard alias.contains(where: { lower.contains($0) }) else { continue }

            let cantidad = extraerCantidad(texto: lower, cerca: alias) ?? 1
            resultado.append(RestockItem(
                productoId: producto.id,
                nombre:     producto.nombre,
                cantidad:   cantidad,
                esQuita:    esQuita,
                imagenAsset: producto.imagenAsset
            ))
        }

        return resultado
    }

    private let verbosQuita = ["quita", "baja", "elimina", "saca", "retira", "reduce", "borra", "menos"]
    private let verbosAgrega = ["agrega", "anade", "pon", "sube", "suma", "mete", "incluye", "mas", "dale"]

    private func aliasProducto(_ p: Producto) -> [String] {
        let normalizar: (String) -> String = { s in
            s.lowercased()
             .replacingOccurrences(of: "á", with: "a").replacingOccurrences(of: "é", with: "e")
             .replacingOccurrences(of: "í", with: "i").replacingOccurrences(of: "ó", with: "o")
             .replacingOccurrences(of: "ú", with: "u").replacingOccurrences(of: "ü", with: "u")
        }
        var alias = [normalizar(p.nombre)]
        if let first = p.nombre.components(separatedBy: " ").first {
            alias.append(normalizar(first))
        }
        switch p.id {
        case "P-001": alias += ["gansito", "gansitos", "marinela gansito"]
        case "P-002": alias += ["pan blanco", "pan bimbo", "pan de caja", "bimbo grande"]
        case "P-003": alias += ["donitas", "donas", "donitas espolvoreadas", "dona"]
        case "P-004": alias += ["pinguinos", "marinela", "pingüinos"]
        case "P-005": alias += ["bimbollos", "bimbollo", "bolillos bimbo"]
        case "P-006": alias += ["nito", "nitos", "pan nito"]
        case "P-007": alias += ["roles", "roles de canela", "rol de canela", "canela"]
        default: break
        }
        return alias
    }

    private func extraerCantidad(texto: String, cerca alias: [String]) -> Int? {
        let palabras = texto.components(separatedBy: .whitespaces)
        for (i, palabra) in palabras.enumerated() {
            let matchAlias = alias.contains(where: { palabra.contains($0) || $0.contains(palabra) })
            guard matchAlias else { continue }
            if i > 0, let n = numero(de: palabras[i - 1]) { return n }
            if i < palabras.count - 1, let n = numero(de: palabras[i + 1]) { return n }
        }
        for palabra in palabras { if let n = numero(de: palabra) { return n } }
        return nil
    }

    private func numero(de palabra: String) -> Int? {
        if let n = Int(palabra) { return n }
        return palabrasNumericas[palabra]
    }

    private let palabrasNumericas: [String: Int] = [
        "un":1,"una":1,"uno":1,"dos":2,"tres":3,"cuatro":4,"cinco":5,
        "seis":6,"siete":7,"ocho":8,"nueve":9,"diez":10,"once":11,
        "doce":12,"trece":13,"catorce":14,"quince":15,"dieciseis":16,
        "diecisiete":17,"dieciocho":18,"diecinueve":19,"veinte":20,
        "veintiuno":21,"veintidos":22,"veinticinco":25,"treinta":30,
        "cuarenta":40,"cincuenta":50,"media":6,"docena":12
    ]
}
