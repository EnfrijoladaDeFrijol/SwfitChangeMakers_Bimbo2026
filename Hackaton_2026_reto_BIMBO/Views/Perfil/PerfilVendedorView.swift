import SwiftUI

// MARK: - Perfil del Vendedor (Premium — toolbar unificada)
struct PerfilVendedorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // HEADER: Logo y Avatar
                    ZStack(alignment: .bottom) {
                        Image("bimbo_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 130)
                            .opacity(0.9)
                            .padding(.bottom, 50)

                        ZStack {
                            Circle()
                                .fill(Color.appBG)
                                .frame(width: 116, height: 116)

                            Circle()
                                .fill(LinearGradient.bimboHero)
                                .frame(width: 108, height: 108)

                            Image(systemName: "person.fill")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: Color.bimboBlue.opacity(0.3), radius: 14, y: 8)
                        .offset(y: 15)
                    }
                    .padding(.top, 10)

                    // Nombre — grande y prominente
                    VStack(spacing: 4) {
                        Text(appState.vendedor.nombreCompleto)
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(Color.bimboNavy)
                        Text(appState.vendedor.vehiculoAsignado)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    // TARJETAS DE INFO — botones grandes con iconos
                    VStack(spacing: 12) {
                        ProfileInfoButton(
                            icon: "location.fill",
                            label: "Zona",
                            value: appState.vendedor.zonaRuta,
                            tint: Color.bimboBlue
                        )
                        ProfileInfoButton(
                            icon: "qrcode",
                            label: "ID",
                            value: appState.vendedor.repartidorId,
                            tint: Color.bimboNavy
                        )
                        ProfileInfoButton(
                            icon: "clock.fill",
                            label: "Turno",
                            value: appState.vendedor.horaInicioTurno,
                            tint: Color.bimboSuccessGreen
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // STATS — botones grandes
                    HStack(spacing: 10) {
                        StatBubble(value: "\(appState.ruta.tiendas.count)", label: "Tiendas", icon: "storefront.fill")
                        StatBubble(value: "\(appState.catalogo.count)", label: "Productos", icon: "shippingbox.fill")
                        StatBubble(value: appState.ruta.rutaActiva, label: "Ruta", icon: "map.fill")
                    }
                    .padding(.horizontal, 20)

                    // Cerrar sesión — botón grande
                    Button {
                        appState.cerrarSesion()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .bold))
                            Text("Cerrar Sesión")
                                .font(.system(size: 17, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.bimboDangerRed)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.bimboDangerRed.opacity(0.3), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
        }
        .toolbar {
            // Logo Bimbo (unificado con mapa y camión)
            ToolbarItem(placement: .topBarLeading) {
                Image("bimbo_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .padding(.leading, 0)
            }
            // Badge perfil
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text("Perfil")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(Color.bimboBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.bimboBlue.opacity(0.15))
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - ProfileInfoButton (botón grande con ícono + label + valor)
struct ProfileInfoButton: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            // Ícono grande
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.system(size: 22, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Color.bimboNavy)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.quaternary)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Stat Bubble (botón grande)
struct StatBubble: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.bimboBlue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.bimboBlue)
            }
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Color.bimboNavy)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// Keep ProfileInfoCard for backward compatibility
struct ProfileInfoCard: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        ProfileInfoButton(icon: icon, label: "", value: value, tint: tint)
    }
}

#Preview {
    NavigationStack {
        PerfilVendedorView()
            .environmentObject(AppState())
    }
}
