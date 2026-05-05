import Foundation

struct StockSugerido {
    let producto: Producto
    var cantidad: Int
    let razon: String
}

final class MLPredictionService {
    static let shared = MLPredictionService()
    private init() {}

    func predecirStock(para tienda: Tienda, catalogo: [Producto]) -> [StockSugerido] {
        catalogo.map { producto in
            let devolucion = tienda.historialDevoluciones[producto.id] ?? "Bajo"
            var cantidad   = baseStock(diasCaducidad: producto.diasCaducidad)
            var razon      = "Demanda estándar"

            if devolucion == "Alto" {
                cantidad = max(1, cantidad - 3)
                razon    = "Historial indica alta devolución en este local"
            }

            // Boost por evento local próximo
            if let evento = tienda.eventosLocales.first,
               let boost  = evento.impactoSugerido[producto.id] {
                let pct = parsePercent(boost)
                cantidad = Int(Double(cantidad) * (1.0 + pct))
                razon    = "\(evento.descripcion) · \(boost) demanda estimada"
            }

            return StockSugerido(producto: producto, cantidad: cantidad, razon: razon)
        }
    }

    private func baseStock(diasCaducidad: Int) -> Int {
        switch diasCaducidad {
        case ...7:  return 4
        case 8...12: return 6
        default:     return 8
        }
    }

    private func parsePercent(_ str: String) -> Double {
        let num = str.replacingOccurrences(of: "%", with: "")
                     .replacingOccurrences(of: "+", with: "")
        return (Double(num) ?? 0) / 100.0
    }
}
