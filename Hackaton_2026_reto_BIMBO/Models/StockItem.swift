import Foundation

// MARK: - StockItem (estado del inventario del camión)
struct StockItem: Identifiable {
    let producto: Producto
    let stockInicial: Int
    var stockActual: Int
    var entregados: Int { stockInicial - stockActual }
    var porcentajeRestante: Double {
        guard stockInicial > 0 else { return 0 }
        return Double(stockActual) / Double(stockInicial)
    }

    var id: String { producto.id }
}
