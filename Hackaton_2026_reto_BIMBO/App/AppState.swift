import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var vendedor:      Vendedor
    @Published var ruta:          Ruta
    @Published var catalogo:      [Producto]
    @Published var tiendaActiva:  Tienda?
    @Published var isLoggedIn:    Bool = false

    /// Inventario global del camión (compartido entre todas las vistas)
    @Published var inventario = InventarioViewModel()

    private var cancellables = Set<AnyCancellable>()

    init() {
        let storage = LocalStorageService.shared
        vendedor  = storage.loadVendedor()
        ruta      = storage.loadRuta()
        catalogo  = storage.loadProductos()

        // Propagar cambios del inventario a AppState para que TODAS las vistas se actualicen
        inventario.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func seleccionar(tienda: Tienda) { tiendaActiva = tienda }
    func deseleccionar()             { tiendaActiva = nil    }

    func cerrarSesion() {
        withAnimation(.spring()) { isLoggedIn = false }
    }
}
