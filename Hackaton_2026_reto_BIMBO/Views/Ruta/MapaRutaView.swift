import SwiftUI
import MapKit

struct MapaRutaView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = RutaViewModel()

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.348, longitude: -99.125),
            span:   MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @State private var sheetAppeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Mapa iOS 17+
            Map(position: $cameraPosition) {
                ForEach(vm.ruta.tiendas) { tienda in
                    Annotation(tienda.nombre, coordinate: tienda.coordenadas.clLocation) {
                        AnimatedTiendaPin(tienda: tienda) {
                            vm.seleccionar(tienda)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .mapStyle(.standard(elevation: .realistic))

            // Sheet flotante inferior con animación
            TiendasListSheet(tiendas: vm.ruta.tiendas) { tienda in
                vm.seleccionar(tienda)
            }
            .offset(y: sheetAppeared ? 0 : 200)
            .opacity(sheetAppeared ? 1 : 0)
        }
        .toolbar {
            // Logo a la izquierda
            ToolbarItem(placement: .topBarLeading) {
                Image("bimbo_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .padding(.leading, 0)
            }

            // Ruta a la derecha
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .font(.caption)
                    Text("R-SUR-08")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(Color.bimboBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.bimboBlue.opacity(0.15))
                .clipShape(Capsule())
            }
        }

        .sheet(isPresented: $vm.showDetalleTienda) {
            if let tienda = vm.tiendaSeleccionada {
                NavigationStack {
                    DetalleTiendaView(tienda: tienda)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                sheetAppeared = true
            }
        }
    }
}

// MARK: - Animated Pin con pulso
private struct AnimatedTiendaPin: View {
    let tienda: Tienda
    let onTap: () -> Void

    @State private var pulse = false
    @State private var appeared = false

    private var pinColor: Color {
        tienda.tieneAlertaCaducidad ? Color.alertAmber : Color.bimboBlue
    }

    var body: some View {
        ZStack {
            // Anillo de pulso
            Circle()
                .stroke(pinColor.opacity(0.3), lineWidth: 2)
                .frame(width: 52, height: 52)
                .scaleEffect(pulse ? 1.4 : 1.0)
                .opacity(pulse ? 0 : 0.6)
                .animation(
                    .easeOut(duration: 1.8)
                    .repeatForever(autoreverses: false),
                    value: pulse
                )

            // Pin principal
            Circle()
                .fill(pinColor)
                .frame(width: 38, height: 38)
                .shadow(color: pinColor.opacity(0.4), radius: 6, y: 3)
                .overlay(
                    Image(systemName: tienda.tieneAlertaCaducidad ? "exclamationmark" : "storefront.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
                .scaleEffect(appeared ? 1.0 : 0.3)
                .opacity(appeared ? 1 : 0)
        }
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double.random(in: 0.1...0.5))) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                pulse = true
            }
        }
    }
}

// MARK: - Sheet inferior
private struct TiendasListSheet: View {
    let tiendas: [Tienda]
    let onSelect: (Tienda) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .frame(maxWidth: .infinity)

            HStack {
                Text("Tiendas de hoy")
                    .font(.title2.bold())
                    .foregroundStyle(Color.bimboNavy)
                Spacer()
                Text("\(tiendas.count)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.bimboBlue)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(tiendas.enumerated()), id: \.element.id) { index, tienda in
                        AnimatedTiendaCard(tienda: tienda, delay: Double(index) * 0.08) {
                            onSelect(tienda)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
        .padding(.horizontal, 8)
    }
}

// MARK: - Animated Tienda Card
private struct AnimatedTiendaCard: View {
    let tienda: Tienda
    let delay: Double
    let onTap: () -> Void

    @State private var appeared = false

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "storefront.fill")
                        .foregroundStyle(Color.bimboBlue)
                    Spacer()
                    if tienda.tieneAlertaCaducidad {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.alertAmber)
                            .font(.caption.bold())
                    }
                }

                Text(tienda.nombre)
                    .font(.sectionTitle)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if !tienda.eventosLocales.isEmpty {
                    Label(tienda.eventosLocales[0].descripcion, systemImage: "calendar")
                        .font(.badgeLabel)
                        .foregroundStyle(Color.bimboBlue)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(width: 160)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                appeared = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        MapaRutaView()
            .environmentObject(AppState())
    }
}
