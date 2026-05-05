import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var vendedor:      Vendedor
    @Published var ruta:          Ruta
    @Published var catalogo:      [Producto]
    @Published var tiendaActiva:  Tienda?
    @Published var isLoggedIn:    Bool = false

    /// Inventario global del camión (compartido entre todas las vistas)
    @Published var inventario = InventarioViewModel()

    init() {
        let storage = LocalStorageService.shared
        vendedor  = storage.loadVendedor()
        ruta      = storage.loadRuta()
        catalogo  = storage.loadProductos()
    }

    func seleccionar(tienda: Tienda) { tiendaActiva = tienda }
    func deseleccionar()             { tiendaActiva = nil    }

    func cerrarSesion() {
        withAnimation(.spring()) { isLoggedIn = false }
    }
}
