
import SwiftUI
 
// MARK: - DetalleTiendaView (Rediseño: Copiloto IA + Override por Voz/Touch)
//
// Filosofía:
// • Una sola pantalla, una sola intención: registrar el surtido en <30s.
// • La IA sugiere, el humano valida o ajusta con stepper directo (HCAI).
// • Voz como acción protagonista (FAB persistente).
// • Verde esmeralda = ingresar. Naranja ámbar = retirar. Suaves, no chillones.
// • Caducidad: glow contextual sobre la card afectada, no sección aparte.
 
struct DetalleTiendaView: View {
    let tienda: Tienda
 
    @StateObject private var vm = PrediccionVentaViewModel()
 
    // Estado de UI
    @State private var modoVoz: ModoVoz? = nil
    @State private var showEvidencia = false
    @State private var showFiltros = false
    @State private var searchText = ""
    @State private var selectedCategoria: String? = nil
    @State private var eventoAnadido = false
    @State private var headerAppeared = false
    @State private var contentAppeared = false
 
    @Environment(\.dismiss) private var dismiss
 
    enum ModoVoz: Identifiable {
        case ingresar, retirar
        var id: Int { self == .ingresar ? 0 : 1 }
    }
 
    // MARK: - Filtrado
    private var productosFiltrados: [StockSugerido] {
        vm.stockSugerido.filter { item in
            let s = searchText.isEmpty ||
                item.producto.nombre.localizedCaseInsensitiveContains(searchText)
            let c = selectedCategoria == nil ||
                item.producto.categoria == selectedCategoria
            return s && c
        }
    }
 
    private var categoriasDisponibles: [String] {
        Array(Set(vm.stockSugerido.map { $0.producto.categoria })).sorted()
    }
 
    private var totalUnidades: Int {
        vm.stockSugerido.reduce(0) { $0 + $1.cantidad }
    }
 
    private var hayCaducidades: Bool {
        !vm.productosConAlertaCaducidad.isEmpty
    }
 
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBG.ignoresSafeArea()
 
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerCompacto
                        .opacity(headerAppeared ? 1 : 0)
                        .offset(y: headerAppeared ? 0 : -16)
 
                    copilotoResumen
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 12)
 
                    listaProductos
                        .opacity(contentAppeared ? 1 : 0)
 
                    Color.clear.frame(height: 180)
                }
                .padding(.top, 12)
            }
 
            barraInferior
 
            if vm.showBannerEvento, let evento = vm.eventoActivo, !eventoAnadido {
                VStack {
                    DynamicContextBanner(
                        evento: evento,
                        onAnadir: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                vm.showBannerEvento = false
                                eventoAnadido = true
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
        .sheet(item: $modoVoz) { modo in
            VoiceRestockBottomSheet(
                tiendaNombre: tienda.nombre,
                modoQuitar: modo == .retirar
            )
        }
        .sheet(isPresented: $showEvidencia) {
            NavigationStack {
                CamaraConteoView()
                    .navigationTitle("Evidencia · \(tienda.nombre)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { showEvidencia = false }
                                .foregroundStyle(Color.bimboBlue)
                        }
                    }
            }
        }
        .sheet(isPresented: $showFiltros) {
            filtrosSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
 
    // MARK: - Header compacto
    private var headerCompacto: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient.bimboHero)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.bimboBlue.opacity(0.25), radius: 10, y: 4)
                Image(systemName: "storefront.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
 
            VStack(alignment: .leading, spacing: 4) {
                Text(tienda.nombre)
                    .font(.title2.bold())
                    .foregroundStyle(Color.bimboNavy)
                    .lineLimit(2)
 
                HStack(spacing: 6) {
                    Text(tienda.id)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.bimboIce)
                        .clipShape(Capsule())
 
                    if hayCaducidades {
                        caducidadBadge
                    }
                }
            }
 
            Spacer()
        }
        .padding(.horizontal, 16)
    }
 
    private var caducidadBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.system(size: 10, weight: .bold))
            Text("\(vm.productosConAlertaCaducidad.count) por caducar")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(Color.bimboWarningOrange)
        .clipShape(Capsule())
        .shadow(color: Color.bimboWarningOrange.opacity(0.4), radius: 6, y: 2)
    }
 
    // MARK: - Resumen del copiloto
    private var copilotoResumen: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.bimboBlue, Color.bimboNavy],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
 
                VStack(alignment: .leading, spacing: 1) {
                    Text("COPILOTO SUGIERE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                    Text("\(totalUnidades) unidades para hoy")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.bimboNavy)
                }
 
                Spacer()
 
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showFiltros = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.bimboBlue)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
 
            // Disclosure: por qué la IA sugiere esto
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.bimboBlue.opacity(0.8))
                    .padding(.top, 2)
 
                Text("Basado en historial de la tienda, caducidad y eventos cercanos. Puedes ajustar libremente cualquier cantidad.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.bimboBlue.opacity(0.06))
            )
            .padding(.horizontal, 16)
        }
    }
 
    // MARK: - Lista de productos
    private var listaProductos: some View {
        VStack(spacing: 10) {
            if productosFiltrados.isEmpty {
                emptyState
            } else {
                ForEach(productosFiltrados, id: \.producto.id) { item in
                    ProductoRowCard(
                        item: item,
                        onIncrement: { incrementar(item) },
                        onDecrement: { decrementar(item) }
                    )
                    .padding(.horizontal, 16)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8),
                   value: productosFiltrados.map { $0.producto.id })
    }
 
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.gray.opacity(0.5))
            Text("Sin coincidencias")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
            if !searchText.isEmpty || selectedCategoria != nil {
                Button {
                    withAnimation(.spring()) {
                        searchText = ""
                        selectedCategoria = nil
                    }
                } label: {
                    Text("Limpiar filtros")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.bimboBlue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
 
    // MARK: - Barra inferior
    private var barraInferior: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SecondaryAction(
                    icon: "camera.fill",
                    label: "Foto",
                    accent: Color.bimboBlue,
                    filled: false
                ) { showEvidencia = true }
 
                SecondaryAction(
                    icon: "checkmark.seal.fill",
                    label: "Guardar",
                    accent: Color.bimboSuccessGreen,
                    filled: true
                ) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    vm.guardarStock(tiendaId: tienda.id)
                    dismiss()
                }
            }
 
            HStack(spacing: 12) {
                VoiceFAB(
                    label: "Ingresar",
                    icon: "plus",
                    color: Color.bimboSuccessGreen
                ) { modoVoz = .ingresar }
 
                VoiceFAB(
                    label: "Retirar",
                    icon: "minus",
                    color: Color.bimboWarningOrange
                ) { modoVoz = .retirar }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [
                    Color.appBG.opacity(0),
                    Color.appBG.opacity(0.85),
                    Color.appBG
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
    }
 
    // MARK: - Filtros sheet
    private var filtrosSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Buscar producto...", text: $searchText)
                        .font(.system(size: 16))
                    if !searchText.isEmpty {
                        Button {
                            withAnimation(.spring()) { searchText = "" }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.gray.opacity(0.5))
                        }
                    }
                }
                .padding(14)
                .background(Color.bimboIce)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
 
                VStack(alignment: .leading, spacing: 10) {
                    Text("CATEGORÍA")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
 
                    FlowLayout(spacing: 8) {
                        CategoryChip(label: "Todos",
                                     isSelected: selectedCategoria == nil) {
                            withAnimation(.spring()) { selectedCategoria = nil }
                        }
                        ForEach(categoriasDisponibles, id: \.self) { cat in
                            CategoryChip(label: cat,
                                         isSelected: selectedCategoria == cat) {
                                withAnimation(.spring()) {
                                    selectedCategoria = selectedCategoria == cat ? nil : cat
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
 
                Spacer()
 
                Button {
                    showFiltros = false
                } label: {
                    Text("Aplicar")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.bimboBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(20)
            .navigationTitle("Filtrar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showFiltros = false }
                }
            }
        }
    }
 
    // MARK: - Acciones de stepper
    private func incrementar(_ item: StockSugerido) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let idx = vm.stockSugerido.firstIndex(where: { $0.producto.id == item.producto.id }) {
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
 
// MARK: - Producto Row Card
private struct ProductoRowCard: View {
    let item: StockSugerido
    let onIncrement: () -> Void
    let onDecrement: () -> Void
 
    private var esCaducidad: Bool {
        item.producto.diasCaducidad <= 10 && item.cantidad > 0
    }
 
    var body: some View {
        HStack(spacing: 14) {
            ProductoThumb(producto: item.producto)
 
            VStack(alignment: .leading, spacing: 4) {
                Text(item.producto.nombre)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
 
                HStack(spacing: 6) {
                    Text(item.producto.categoria)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
 
                    if esCaducidad {
                        caducidadInline
                    }
                }
            }
 
            Spacer(minLength: 4)
 
            stepperGroup
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(cardBorder)
        .shadow(
            color: esCaducidad
                ? Color.bimboWarningOrange.opacity(0.15)
                : Color.black.opacity(0.04),
            radius: esCaducidad ? 10 : 6,
            y: 3
        )
    }
 
    private var caducidadInline: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock.fill")
                .font(.system(size: 8))
            Text("\(item.producto.diasCaducidad)d")
                .font(.system(size: 10, weight: .black))
        }
        .foregroundStyle(Color.bimboWarningOrange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.bimboWarningOrange.opacity(0.15))
        .clipShape(Capsule())
    }
 
    private var stepperGroup: some View {
        HStack(spacing: 0) {
            MiniStepperButton(
                icon: "minus",
                color: Color.bimboWarningOrange,
                enabled: item.cantidad > 0,
                action: onDecrement
            )
 
            Text("\(item.cantidad)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.bimboNavy)
                .frame(minWidth: 40)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: item.cantidad)
 
            MiniStepperButton(
                icon: "plus",
                color: Color.bimboSuccessGreen,
                enabled: true,
                action: onIncrement
            )
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.bimboIce.opacity(0.6)))
    }
 
    @ViewBuilder
    private var cardBorder: some View {
        if esCaducidad {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.bimboWarningOrange.opacity(0.5), lineWidth: 1.5)
        }
    }
}
 
// MARK: - Producto Thumbnail (extraído para que el compilador no se ahogue)
private struct ProductoThumb: View {
    let producto: Producto
 
    var body: some View {
        thumbContent
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.bimboIce.opacity(0.5))
            )
    }
 
    @ViewBuilder
    private var thumbContent: some View {
        if producto.tieneImagen {
            Image(producto.imagenAsset)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.bimboBlue.opacity(0.5))
        }
    }
}
 
// MARK: - Mini Stepper Button (renombrado para no chocar con el global StepperButton)
private struct MiniStepperButton: View {
    let icon: String
    let color: Color
    let enabled: Bool
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(enabled ? color : Color.gray.opacity(0.4))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
 
// MARK: - Voice FAB
private struct VoiceFAB: View {
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
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                }
 
                VStack(alignment: .leading, spacing: 0) {
                    Text(label)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                    HStack(spacing: 3) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Voz")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.white.opacity(0.85))
                }
 
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: color.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}
 
// MARK: - Secondary Action
private struct SecondaryAction: View {
    let icon: String
    let label: String
    let accent: Color
    let filled: Bool
    let action: () -> Void
 
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(label)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(filled ? Color.white : accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(filled ? accent : accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(actionBorder)
        }
        .buttonStyle(.plain)
    }
 
    @ViewBuilder
    private var actionBorder: some View {
        if !filled {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.3), lineWidth: 1)
        }
    }
}
 
// MARK: - Category Chip
private struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
 
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Color.bimboNavy)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.bimboBlue : Color.bimboIce)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
 
// MARK: - FlowLayout
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
 
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
 
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth {
                totalHeight += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }
 
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
 
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
 
#Preview {
    NavigationStack {
        DetalleTiendaView(tienda: Tienda.mockTiendas[0])
    }
}
