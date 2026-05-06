import SwiftUI

// MARK: - InventarioProductoCard (tarjeta con imagen GRANDE y prominente)
struct InventarioProductoCard: View {
    let item: StockItem
    let isAnimating: Bool

    private var porcentaje: Double { item.porcentajeRestante }
    private var progressColor: Color {
        if porcentaje > 0.5    { return Color.bimboSuccessGreen }
        if porcentaje > 0.2    { return Color.bimboWarningOrange }
        return Color.bimboDangerRed
    }

    var body: some View {
        HStack(spacing: 16) {
            // ─── Imagen GRANDE y prominente ───
            productImage

            // ─── Info ───
            VStack(alignment: .leading, spacing: 8) {
                Text(item.producto.nombre)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Color.bimboNavy)
                    .lineLimit(1)
                
                Text(String(format: "$%.2f", item.producto.precioSugerido))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.bimboSuccessGreen)

                // Barra de progreso
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.bimboIce)
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 5)
                            .fill(progressColor)
                            .frame(width: geo.size.width * porcentaje, height: 10)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: porcentaje)
                    }
                }
                .frame(height: 10)

                // Números grandes
                HStack(spacing: 0) {
                    Text("\(item.stockActual)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(progressColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: item.stockActual)
                    Text(" / \(item.stockInicial)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    // Badge entregados
                    if item.entregados > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .black))
                            Text("\(item.entregados)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.bimboSuccessGreen)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(animationBorder)
        .shadow(
            color: isAnimating
                ? Color.bimboSuccessGreen.opacity(0.25)
                : Color.black.opacity(0.05),
            radius: isAnimating ? 14 : 8,
            y: 4
        )
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
    }

    // ─── Imagen de producto grande que sobresale ───
    private var productImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.bimboIce, Color.bimboIce.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)

            if item.producto.tieneImagen {
                Image(item.producto.imagenAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    // La imagen sobresale ligeramente
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.bimboBlue.opacity(0.4))
            }
        }
        // La imagen sobresale por arriba de la card
        .offset(y: -4)
    }

    @ViewBuilder
    private var animationBorder: some View {
        if isAnimating {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.bimboSuccessGreen.opacity(0.5), lineWidth: 2)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        InventarioProductoCard(
            item: StockItem(
                producto: Producto.hardcoded[0],
                stockInicial: 30,
                stockActual: 22
            ),
            isAnimating: false
        )
        InventarioProductoCard(
            item: StockItem(
                producto: Producto.hardcoded[2],
                stockInicial: 20,
                stockActual: 3
            ),
            isAnimating: true
        )
    }
    .padding()
}
