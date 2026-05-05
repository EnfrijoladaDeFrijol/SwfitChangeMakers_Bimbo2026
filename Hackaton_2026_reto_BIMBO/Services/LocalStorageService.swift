import Foundation

final class LocalStorageService {
    static let shared = LocalStorageService()
    private init() {}

    func loadProductos() -> [Producto] { Producto.mockCatalogo }
    func loadRuta()      -> Ruta       { Ruta.mock }
    func loadVendedor()  -> Vendedor   { Vendedor.mock }

    // Persiste ajustes de inventario por tienda en UserDefaults
    private func key(tienda: String) -> String { "stock_\(tienda)" }

    func saveStock(_ items: [String: Int], tiendaId: String) {
        UserDefaults.standard.set(items, forKey: key(tienda: tiendaId))
    }

    func loadStock(tiendaId: String) -> [String: Int] {
        UserDefaults.standard.dictionary(forKey: key(tienda: tiendaId)) as? [String: Int] ?? [:]
    }
}
