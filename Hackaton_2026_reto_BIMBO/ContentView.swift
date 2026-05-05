import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            // PESTAÑA 1: Ruta
            NavigationStack {
                MapaRutaView()
            }
            .tabItem {
                Label("Mi Ruta", systemImage: "map.fill")
            }

            // PESTAÑA 2: Inventario (Mi Camión)
            NavigationStack {
                InventarioView()
            }
            .tabItem {
                Label("Mi Camión", systemImage: "box.truck.fill")
            }

            // PESTAÑA 3: Perfil
            NavigationStack {
                PerfilVendedorView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(Color.bimboBlue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
