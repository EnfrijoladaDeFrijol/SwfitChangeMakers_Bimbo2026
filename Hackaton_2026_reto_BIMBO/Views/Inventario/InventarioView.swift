import SwiftUI

// MARK: - InventarioView (Mi Camión)
struct InventarioView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    @State private var searchText = ""

    private var vm: InventarioViewModel { appState.inventario }

    private var stockFiltrado: [StockItem] {
        guard !searchText.isEmpty else { return vm.stock }
        return vm.stock.filter {
            $0.producto.nombre.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header visual
                    InventarioHeaderView(vm: vm)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -20)

                    // Banner de ventas totales
                    ventasBanner
                        .padding(.horizontal, 16)
                        .opacity(appeared ? 1 : 0)

                    // Barra búsqueda
                    searchBar
                        .padding(.horizontal, 16)

                    // Sección título
                    HStack {
                        Text("Productos")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(Color.bimboNavy)
                        Spacer()
                        Text("\(stockFiltrado.count)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.bimboBlue)
                            .clipShape(Circle())
                    }
                    .padding(.horizontal, 20)

                    // Lista
                    LazyVStack(spacing: 12) {
                        ForEach(stockFiltrado) { item in
                            InventarioProductoCard(
                                item: item,
                                isAnimating: vm.animateDelivery == item.producto.id
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .animation(.spring(response: 0.4), value: vm.stock.map { $0.stockActual })

                    // ─── BOTÓN DE REINICIO DE STOCK (SOLO DEMO) ───
                    Button {
                        vm.reiniciarStockDelCamion()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Reiniciar Camión (Demo)")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.bimboWarningOrange)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.bimboWarningOrange.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.bimboWarningOrange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)

                    Spacer().frame(height: 32)
                }
                .padding(.top, 8)
            }
        }
        .toolbar {
            // Logo Bimbo a la izquierda (igual que en el mapa)
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
                    Image(systemName: "box.truck.fill")
                        .font(.caption)
                    Text("Mi Camión")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(Color.bimboBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.bimboBlue.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.bimboBlue)
                .font(.system(size: 16, weight: .bold))
            TextField("Buscar producto...", text: $searchText)
                .font(.system(size: 16, weight: .medium))
            if !searchText.isEmpty {
                Button {
                    withAnimation(.spring()) { searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.bimboBlue.opacity(0.12), lineWidth: 1)
        )
    }

    private var ventasBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total de Venta Realizada")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(String(format: "$%.2f", vm.totalVentasRealizadas))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bimboMoneySoft)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: vm.totalVentasRealizadas)
            }
            Spacer()
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.bimboMoneySoft.opacity(0.18))
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.bimboMoneySoft.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        InventarioView()
            .environmentObject(AppState())
    }
}
