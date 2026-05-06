import SwiftUI

// MARK: - InventarioViewModel
@MainActor
final class InventarioViewModel: ObservableObject {
    @Published var stock: [StockItem] = []
    @Published var animateDelivery: String? = nil

    // Entregas por tienda (historial de la jornada)
    @Published var entregasPorTienda: [String: [String: Int]] = [:]  // [tiendaId: [productoId: cantidad]]

    var totalProductos: Int    { stock.reduce(0) { $0 + $1.stockInicial } }
    var totalEntregados: Int   { stock.reduce(0) { $0 + $1.entregados } }
    var totalRestantes: Int    { stock.reduce(0) { $0 + $1.stockActual } }
    var totalVentasRealizadas: Double {
        stock.reduce(0) { total, item in
            let cantidadVendida = item.stockInicial - item.stockActual
            return total + (Double(cantidadVendida) * item.producto.precioSugerido)
        }
    }
    var porcentajeGlobal: Double {
        guard totalProductos > 0 else { return 0 }
        return Double(totalEntregados) / Double(totalProductos)
    }

    /// Productos próximos a caducar en el camión (días <= 10 y hay stock)
    var productosPorCaducar: [StockItem] {
        stock.filter { $0.producto.diasCaducidad <= 10 && $0.stockActual > 0 }
    }

    init() {
        cargarInventarioInicial()
    }

    func cargarInventarioInicial() {
        let catalogo = Producto.mockCatalogo
        let cantidades: [String: Int] = [
            "P-001": 30, "P-002": 25, "P-003": 20, "P-004": 15,
            "P-005": 18, "P-006": 22, "P-007": 16,
        ]

        // Intenta cargar el estado guardado, si no usa las cantidades iniciales
        let saved = UserDefaults.standard.dictionary(forKey: "camion_stock") as? [String: Int]

        stock = catalogo.map { producto in
            let inicial = cantidades[producto.id] ?? 10
            let actual  = saved?[producto.id] ?? inicial
            return StockItem(
                producto: producto,
                stockInicial: inicial,
                stockActual: min(actual, inicial)
            )
        }
    }

    /// Persiste el estado actual del camión
    func guardarEstado() {
        let dict = Dictionary(uniqueKeysWithValues: stock.map { ($0.producto.id, $0.stockActual) })
        UserDefaults.standard.set(dict, forKey: "camion_stock")
    }

    /// Entrega producto (resta del camión)
    func entregarProducto(id: String, cantidad: Int) {
        guard let idx = stock.firstIndex(where: { $0.producto.id == id }),
              stock[idx].stockActual >= cantidad else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            stock[idx].stockActual -= cantidad
            animateDelivery = id
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        guardarEstado()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.animateDelivery = nil
        }
    }

    /// Devuelve producto al camión
    func devolverProducto(id: String, cantidad: Int) {
        guard let idx = stock.firstIndex(where: { $0.producto.id == id }) else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            stock[idx].stockActual = min(
                stock[idx].stockInicial,
                stock[idx].stockActual + cantidad
            )
            animateDelivery = id
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guardarEstado()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.animateDelivery = nil
        }
    }

    /// Registra entrega a una tienda específica
    func registrarEntrega(tiendaId: String, productoId: String, cantidad: Int) {
        entregarProducto(id: productoId, cantidad: cantidad)
        var tiendaDict = entregasPorTienda[tiendaId] ?? [:]
        tiendaDict[productoId] = (tiendaDict[productoId] ?? 0) + cantidad
        entregasPorTienda[tiendaId] = tiendaDict
    }

    /// Registra devolución desde una tienda
    func registrarDevolucion(tiendaId: String, productoId: String, cantidad: Int) {
        devolverProducto(id: productoId, cantidad: cantidad)
        var tiendaDict = entregasPorTienda[tiendaId] ?? [:]
        tiendaDict[productoId] = max(0, (tiendaDict[productoId] ?? 0) - cantidad)
        entregasPorTienda[tiendaId] = tiendaDict
    }

    /// Procesa un array de RestockItems
    func procesarRestock(items: [RestockItem], tiendaId: String = "") {
        for item in items {
            if item.esQuita {
                if tiendaId.isEmpty {
                    devolverProducto(id: item.productoId, cantidad: item.cantidad)
                } else {
                    registrarDevolucion(tiendaId: tiendaId, productoId: item.productoId, cantidad: item.cantidad)
                }
            } else {
                if tiendaId.isEmpty {
                    entregarProducto(id: item.productoId, cantidad: item.cantidad)
                } else {
                    registrarEntrega(tiendaId: tiendaId, productoId: item.productoId, cantidad: item.cantidad)
                }
            }
        }
    }

    /// Cuánto se dejó en una tienda específica
    func entregadosEn(tiendaId: String) -> [String: Int] {
        entregasPorTienda[tiendaId] ?? [:]
    }

    /// Stock disponible en camión para un producto
    func stockDisponible(productoId: String) -> Int {
        stock.first(where: { $0.producto.id == productoId })?.stockActual ?? 0
    }

    /// Reinicia el stock a sus valores iniciales y limpia las entregas (solo fines de demo)
    func reiniciarStockDelCamion() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            for i in 0..<stock.count {
                stock[i].stockActual = stock[i].stockInicial
            }
            entregasPorTienda.removeAll()
            UserDefaults.standard.removeObject(forKey: "camion_stock")
        }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}
