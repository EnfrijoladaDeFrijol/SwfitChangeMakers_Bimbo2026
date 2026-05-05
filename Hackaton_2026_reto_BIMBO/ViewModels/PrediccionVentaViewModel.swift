import SwiftUI

@MainActor
final class PrediccionVentaViewModel: ObservableObject {
    @Published var stockSugerido:  [StockSugerido] = []
    @Published var showBannerEvento                = false
    @Published var eventoActivo:   EventoLocal?    = nil

    private let predictor = MLPredictionService.shared
    private let storage   = LocalStorageService.shared

    func cargar(tienda: Tienda) {
        let catalogo  = storage.loadProductos()
        stockSugerido = predictor.predecirStock(para: tienda, catalogo: catalogo)

        if let evento = tienda.eventosLocales.first {
            eventoActivo    = evento
            showBannerEvento = true
        }
    }

    func ajustar(productoId: String, delta: Int) {
        guard let idx = stockSugerido.firstIndex(where: { $0.producto.id == productoId }) else { return }
        stockSugerido[idx].cantidad = max(0, stockSugerido[idx].cantidad + delta)
    }

    func guardarStock(tiendaId: String) {
        let dict = Dictionary(uniqueKeysWithValues: stockSugerido.map { ($0.producto.id, $0.cantidad) })
        storage.saveStock(dict, tiendaId: tiendaId)
    }

    var productosConAlertaCaducidad: [StockSugerido] {
        stockSugerido.filter { $0.producto.diasCaducidad <= 10 && $0.cantidad > 0 }
    }
}
