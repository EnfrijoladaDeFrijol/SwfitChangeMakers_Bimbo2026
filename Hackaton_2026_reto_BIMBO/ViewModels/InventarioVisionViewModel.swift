import SwiftUI

@MainActor
final class InventarioVisionViewModel: ObservableObject {
    @Published var stockItems:    [StockSugerido] = []
    @Published var showAjuste     = false
    @Published var showCamara     = false

    let speech  = SpeechService()
    let vision  = VisionService()
    private let storage = LocalStorageService.shared

    func iniciarDictado() { Task { await speech.solicitarPermiso(); speech.iniciar() } }
    func detenerDictado() {
        speech.detener()
        let catalogo = storage.loadProductos()
        let parsed   = speech.parsearDictado(speech.transcripcion, catalogo: catalogo)
        if !parsed.isEmpty {
            let predictor = MLPredictionService.shared
            var sugerido  = predictor.predecirStock(para: Ruta.mock.tiendas[0], catalogo: catalogo)
            for (id, qty) in parsed {
                if let idx = sugerido.firstIndex(where: { $0.producto.id == id }) {
                    sugerido[idx].cantidad = qty
                }
            }
            stockItems = sugerido
            showAjuste = true
        }
    }

    func ajustar(productoId: String, delta: Int) {
        guard let idx = stockItems.firstIndex(where: { $0.producto.id == productoId }) else { return }
        stockItems[idx].cantidad = max(0, stockItems[idx].cantidad + delta)
    }
}
