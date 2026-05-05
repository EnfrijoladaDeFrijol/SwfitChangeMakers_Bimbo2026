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

            // PESTAÑA 2: Perfil
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

// MARK: - Perfil del Vendedor (Premium con logo Bimbo)
private struct PerfilVendedorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                // Aumentamos el spacing general para que la interfaz respire
                VStack(spacing: 24) {

                    // HEADER: Logo y Avatar
                    ZStack(alignment: .bottom) {
                        // 1. Logo Bimbo (Actuando como banner)
                        Image("bimbo_logo")
                            .resizable()
                            .scaledToFit()
                            // Altura más equilibrada
                            .frame(height: 120)
                            .opacity(0.9)
                            // Damos espacio en la parte inferior para que quepa la mitad del avatar
                            .padding(.bottom, 50)

                        // 2. Avatar del repartidor superpuesto
                        ZStack {
                            // Fondo sólido para que el logo no se transparente detrás del avatar
                            Circle()
                                .fill(Color.appBG)
                                .frame(width: 112, height: 112)
                            
                            Circle()
                                .fill(LinearGradient.bimboHero) // Asegúrate de tener este gradiente definido
                                .frame(width: 104, height: 104)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 46, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: Color.bimboBlue.opacity(0.3), radius: 12, y: 8)
                        // Lo bajamos ligeramente para lograr el efecto de superposición
                        .offset(y: 15)
                    }
                    .padding(.top, 10)

                    // TEXTOS: Nombre y vehículo
                    VStack(spacing: 6) {
                        Text(appState.vendedor.nombreCompleto)
                            .font(.title2.bold()) // Ajustado a title2 para mejor proporción
                            .foregroundStyle(Color.bimboNavy)
                        Text(appState.vendedor.vehiculoAsignado)
                            .font(.callout) // Ajustado a callout
                            .foregroundStyle(.secondary)
                    }

                    // TARJETAS DE INFO
                    VStack(spacing: 12) {
                        ProfileInfoCard(
                            icon: "location.fill",
                            value: appState.vendedor.zonaRuta,
                            tint: Color.bimboBlue
                        )
                        ProfileInfoCard(
                            icon: "qrcode",
                            value: appState.vendedor.repartidorId,
                            tint: Color.bimboNavy
                        )
                        ProfileInfoCard(
                            icon: "clock.fill",
                            value: "Inicio: \(appState.vendedor.horaInicioTurno)",
                            tint: Color.bimboSuccessGreen // Asegúrate de tener este color definido
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // STATS RÁPIDAS
                    HStack(spacing: 12) {
                        StatBubble(value: "\(appState.ruta.tiendas.count)", label: "Tiendas", icon: "storefront.fill")
                        StatBubble(value: "\(appState.catalogo.count)", label: "Productos", icon: "shippingbox.fill")
                        StatBubble(value: appState.ruta.rutaActiva, label: "Ruta", icon: "map.fill")
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile Info Card (minimalista)
private struct ProfileInfoCard: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.system(size: 18, weight: .semibold))
            }

            Text(value)
                .font(.sectionTitle)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Stat Bubble
private struct StatBubble: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.bimboBlue)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color.bimboNavy)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
