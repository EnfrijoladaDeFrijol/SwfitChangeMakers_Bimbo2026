import SwiftUI
import AVFoundation

enum FotoEtapa: String, CaseIterable {
    case antes   = "Antes"
    case despues = "Después"

    var icono: String {
        switch self {
        case .antes:   return "camera"
        case .despues: return "checkmark.camera"
        }
    }
    var index: Int { FotoEtapa.allCases.firstIndex(of: self) ?? 0 }
}

@MainActor
final class VisionService: ObservableObject {
    @Published var etapaActual: FotoEtapa = .antes
    @Published var fotoAntes:   UIImage?  = nil
    @Published var fotoDespues: UIImage?  = nil
    @Published var completado:  Bool      = false

    func guardarFoto(_ imagen: UIImage) {
        switch etapaActual {
        case .antes:
            fotoAntes   = imagen
            etapaActual = .despues
        case .despues:
            fotoDespues = imagen
            completado  = true
        }
    }

    func reset() {
        etapaActual = .antes
        fotoAntes   = nil
        fotoDespues = nil
        completado  = false
    }
}
