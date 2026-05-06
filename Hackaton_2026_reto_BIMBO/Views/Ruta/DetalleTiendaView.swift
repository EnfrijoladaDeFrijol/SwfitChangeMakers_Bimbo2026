
import SwiftUI
 
// MARK: - DetalleTiendaView (Rediseño completo: paso a paso intuitivo)
//
// Flujo mental del repartidor:
//  PASO 1 → Retirar caducados  (naranja, mic integrado)
//  PASO 2 → Surtir estante     (verde, IA sugiere, mic integrado)
//  📷     → Evidencia flotante (antes/después)
 
struct DetalleTiendaView: View {
    let tienda: Tienda
 
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = PrediccionVentaViewModel()
 
    @State private var modoVoz: ModoVoz? = nil
    @State private var showEvidencia = false
    @State private var headerAppeared = false
    @State private var contentAppeared = false
    @Environment(\.dismiss) private var dismiss
 
    enum ModoVoz: Identifiable {
        case ingresar, retirar
        var id: Int { self == .ingresar ? 0 : 1 }
    }
 
    private var inventario: InventarioViewModel { appState.inventario }
 
    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
 
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ─── Header ───
                    tiendaHeader
                        .opacity(headerAppeared ? 1 : 0)
                        .offset(y: headerAppeared ? 0 : -16)
 
                    // ─── PASO 1: Retirar caducados ───
                    paso1Caducados
                        .padding(.top, 20)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)

                    // ─── Separador visual ───
                    sectionDivider

                    // ─── PASO 2: Surtir estante (IA sugiere) ───
                    paso2Surtir
                        .padding(.top, 4)
                        .opacity(contentAppeared ? 1 : 0)

                    // ─── Separador visual ───
                    sectionDivider

                    // ─── Resumen entregas a esta tienda ───
                    resumenEntregas
                        .padding(.top, 4)

                    // ─── Guardar ───
                    botonGuardar
                        .padding(.top, 28)
                        .padding(.bottom, 100)
                }
                .padding(.top, 12)
            }
 
            // FAB cámara flotante
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    cameraFAB
                        .padding(.trailing, 20)
                        .padding(.bottom, 28)
                }
            }
 
            // Banner evento
            if vm.showBannerEvento, let evento = vm.eventoActivo {
                VStack {
                    DynamicContextBanner(
                        evento: evento,
                        onAnadir: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                vm.showBannerEvento = false
                            }
                        },
                        onIgnorar: {
                            withAnimation(.spring()) { vm.showBannerEvento = false }
                        }
                    )
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image("bimbo_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
                    .opacity(0.8)
            }
        }
        .sheet(item: $modoVoz) { modo in
            VoiceRestockBottomSheet(
                tiendaNombre: tienda.nombre,
                tiendaId: tienda.id,
                modoQuitar: modo == .retirar
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showEvidencia) {
            NavigationStack {
                CamaraConteoView()
                    .navigationTitle("📷 \(tienda.nombre)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { showEvidencia = false }
                                .foregroundStyle(Color.bimboBlue)
                        }
                    }
            }
        }
        .onAppear {
            vm.cargar(tienda: tienda)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                headerAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.2)) {
                contentAppeared = true
            }
        }
    }
 
    // ═══════════════════════════════════════════════════
    // MARK: - Header
    // ═══════════════════════════════════════════════════
    private var tiendaHeader: some View {
        VStack(spacing: 10) {
            // Ícono grande centrado
            ZStack {
                Circle()
                    .fill(LinearGradient.bimboHero)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.bimboBlue.opacity(0.2), radius: 12, y: 4)
                Image(systemName: "storefront.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Nombre de la tienda — GRANDE y CENTRADO
            Text(tienda.nombre)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Color.bimboNavy)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Badges
            HStack(spacing: 8) {
                Text(tienda.id)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.bimboIce)
                    .clipShape(Capsule())

                if !inventario.productosPorCaducar.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("\(inventario.productosPorCaducar.count) caducan")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.bimboWarningOrange)
                    .clipShape(Capsule())
                }

                // Stock del camión
                HStack(spacing: 4) {
                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 10))
                    Text("\(inventario.totalRestantes) en camión")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.bimboBlue)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
 
    // ═══════════════════════════════════════════════════
    // MARK: - PASO 1: Retirar caducados
    // ═══════════════════════════════════════════════════
    private var paso1Caducados: some View {
        VStack(spacing: 14) {
            // Encabezado del paso
            PasoHeader(
                number: 1,
                title: "Retirar caducados",
                subtitle: "Quita del estante lo que está por vencer",
                icon: "clock.badge.exclamationmark.fill",
                color: Color.bimboWarningOrange
            )
            .padding(.horizontal, 16)
 
            if inventario.productosPorCaducar.isEmpty {
                // Sin caducados
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.bimboSuccessGreen)
                    Text("Sin productos por caducar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
            } else {
                // Lista de caducados
                VStack(spacing: 8) {
                    ForEach(inventario.productosPorCaducar) { item in
                        CaducadoRow(
                            item: item,
                            onRetirar: {
                                inventario.registrarDevolucion(
                                    tiendaId: tienda.id,
                                    productoId: item.producto.id,
                                    cantidad: 1
                                )
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
 
                // Botón voz para quitar
                VoiceActionButton(
                    label: "Retirar por voz",
                    icon: "mic.fill",
                    color: Color.bimboWarningOrange
                ) { modoVoz = .retirar }
                .padding(.horizontal, 16)
            }
        }
    }
 
    // ═══════════════════════════════════════════════════
    // MARK: - PASO 2: Surtir estante
    // ═══════════════════════════════════════════════════
    private var paso2Surtir: some View {
        VStack(spacing: 14) {
            PasoHeader(
                number: 2,
                title: "Surtir estante",
                subtitle: "IA sugiere basado en histórico de ventas",
                icon: "sparkles",
                color: Color.bimboBlue
            )
            .padding(.horizontal, 16)
 
            // Texto HCAI
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.bimboBlue)
                    .padding(.top, 2)
                Text("Ajusta las cantidades con los botones. Lo que dejes se descuenta de tu camión.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.bimboBlue.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
 
            // Lista de productos sugeridos
            VStack(spacing: 8) {
                ForEach(vm.stockSugerido, id: \.producto.id) { item in
                    SurtidoRow(
                        item: item,
                        disponibleEnCamion: inventario.stockDisponible(productoId: item.producto.id),
                        onIncrement: { incrementar(item) },
                        onDecrement: { decrementar(item) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8),
                       value: vm.stockSugerido.map { $0.cantidad })
 
            // Botón voz para agregar
            VoiceActionButton(
                label: "Agregar por voz",
                icon: "mic.fill",
                color: Color.bimboSuccessGreen
            ) { modoVoz = .ingresar }
            .padding(.horizontal, 16)
        }
    }
 
    // ═══════════════════════════════════════════════════
    // MARK: - Resumen de entregas a esta tienda
    // ═══════════════════════════════════════════════════
    private var resumenEntregas: some View {
        let entregas = inventario.entregadosEn(tiendaId: tienda.id)
        let total = entregas.values.reduce(0, +)
 
        return Group {
            if total > 0 {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.clipboard.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.bimboBlue)
                        Text("Dejaste en esta tienda")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.bimboNavy)
                        Spacer()
                        Text("\(total) uds")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(Color.bimboBlue)
                    }
                    .padding(.horizontal, 16)
 
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(entregas.keys.sorted()), id: \.self) { productoId in
                                if let cantidad = entregas[productoId], cantidad > 0,
                                   let producto = Producto.mockCatalogo.first(where: { $0.id == productoId }) {
                                    EntregaChip(producto: producto, cantidad: cantidad)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
 
    // ═══════════════════════════════════════════════════
    // MARK: - Guardar
    // ═══════════════════════════════════════════════════
    private var botonGuardar: some View {
        Button {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // Procesar las cantidades sugeridas como entregas reales
            for item in vm.stockSugerido where item.cantidad > 0 {
                let yaEntregado = inventario.entregadosEn(tiendaId: tienda.id)[item.producto.id] ?? 0
                let nuevo = item.cantidad - yaEntregado
                if nuevo > 0 {
                    inventario.registrarEntrega(
                        tiendaId: tienda.id,
                        productoId: item.producto.id,
                        cantidad: nuevo
                    )
                }
            }
            vm.guardarStock(tiendaId: tienda.id)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22, weight: .bold))
                Text("Guardar y Salir")
                    .font(.system(size: 18, weight: .heavy))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.bimboSuccessGreen)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.bimboSuccessGreen.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
 
    // ═══════════════════════════════════════════════════
    // MARK: - FAB Cámara flotante
    // ═══════════════════════════════════════════════════
    private var cameraFAB: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showEvidencia = true
        } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient.bimboHero)
                    .frame(width: 62, height: 62)
                    .shadow(color: Color.bimboBlue.opacity(0.4), radius: 12, y: 6)
                Image(systemName: "camera.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tomar foto de evidencia")
    }
 
    // ═══════════════════════════════════════════════════
    // MARK: - Separador de secciones
    // ═══════════════════════════════════════════════════
    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.bimboIce)
            .frame(height: 1.5)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
    }

    // MARK: - Helpers
    private func incrementar(_ item: StockSugerido) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let disponible = inventario.stockDisponible(productoId: item.producto.id)
        if let idx = vm.stockSugerido.firstIndex(where: { $0.producto.id == item.producto.id }),
           vm.stockSugerido[idx].cantidad < disponible {
            vm.stockSugerido[idx].cantidad += 1
        }
    }
 
    private func decrementar(_ item: StockSugerido) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let idx = vm.stockSugerido.firstIndex(where: { $0.producto.id == item.producto.id }),
           vm.stockSugerido[idx].cantidad > 0 {
            vm.stockSugerido[idx].cantidad -= 1
        }
    }
}
 
// ═══════════════════════════════════════════════════════
// MARK: - Sub-componentes
// ═══════════════════════════════════════════════════════
 
// MARK: Paso Header (número + título + ícono)
private struct PasoHeader: View {
    let number: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
 
    var body: some View {
        HStack(spacing: 12) {
            // Número de paso
            Text("\(number)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 6, y: 3)
 
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(color)
                    Text(title)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(Color.bimboNavy)
                }
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
 
            Spacer()
        }
    }
}
 
// MARK: Caducado Row
private struct CaducadoRow: View {
    let item: StockItem
    let onRetirar: () -> Void
 
    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail GRANDE
            ProductoThumb(producto: item.producto, size: 76)
 
            VStack(alignment: .leading, spacing: 4) {
                Text(item.producto.nombre)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.bimboNavy)
                    .lineLimit(1)
                Text(String(format: "$%.2f", item.producto.precioSugerido))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.bimboSuccessGreen)
                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(item.producto.diasCaducidad)d")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                    Text("· \(item.stockActual) uds")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.bimboWarningOrange)
            }
 
            Spacer()
 
            // Botón retirar
            Button(action: onRetirar) {
                HStack(spacing: 5) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .black))
                    Text("1")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.bimboWarningOrange)
                .clipShape(Capsule())
                .shadow(color: Color.bimboWarningOrange.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.bimboWarningOrange.opacity(0.3), lineWidth: 1)
        )
    }
}
 
// MARK: Surtido Row (paso 2, con stepper e imagen grande)
private struct SurtidoRow: View {
    let item: StockSugerido
    let disponibleEnCamion: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
 
    var body: some View {
        HStack(spacing: 14) {
            // Imagen GRANDE
            ProductoThumb(producto: item.producto, size: 76)
 
            VStack(alignment: .leading, spacing: 4) {
                Text(item.producto.nombre)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.bimboNavy)
                    .lineLimit(1)
                Text(String(format: "$%.2f", item.producto.precioSugerido))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.bimboSuccessGreen)
                HStack(spacing: 5) {
                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(disponibleEnCamion) disp.")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color.bimboBlue.opacity(0.7))
            }
 
            Spacer(minLength: 4)
 
            // Stepper
            HStack(spacing: 0) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(item.cantidad > 0 ? Color.bimboWarningOrange : Color.gray.opacity(0.4))
                        .frame(width: 46, height: 46)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(item.cantidad <= 0)
 
                Text("\(item.cantidad)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.bimboNavy)
                    .frame(minWidth: 38)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: item.cantidad)
 
                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(item.cantidad < disponibleEnCamion ? Color.bimboSuccessGreen : Color.gray.opacity(0.4))
                        .frame(width: 46, height: 46)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(item.cantidad >= disponibleEnCamion)
            }
            .padding(.horizontal, 4)
            .background(Capsule().fill(Color.bimboIce.opacity(0.6)))
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
 
// MARK: Voice Action Button (largo, con mic)
private struct VoiceActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void
 
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
 
                Text(label)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
 
                Spacer()
 
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: color.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}
 
// MARK: Entrega Chip (resumen horizontal)
private struct EntregaChip: View {
    let producto: Producto
    let cantidad: Int
 
    var body: some View {
        HStack(spacing: 6) {
            ProductoThumb(producto: producto, size: 28)
            Text("\(cantidad)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(Color.bimboNavy)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.bimboSuccessGreen.opacity(0.1))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.bimboSuccessGreen.opacity(0.3), lineWidth: 1)
        )
    }
}
 
// MARK: Producto Thumbnail (reutilizable)
private struct ProductoThumb: View {
    let producto: Producto
    var size: CGFloat = 56
 
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(Color.bimboIce.opacity(0.5))
                .frame(width: size, height: size)
            if producto.tieneImagen {
                Image(producto.imagenAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.8, height: size * 0.8)
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(Color.bimboBlue.opacity(0.5))
            }
        }
    }
}
 
#Preview {
    NavigationStack {
        DetalleTiendaView(tienda: Tienda.mockTiendas[0])
            .environmentObject(AppState())
    }
}
