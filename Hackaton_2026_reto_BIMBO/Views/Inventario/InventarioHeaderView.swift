import SwiftUI

// MARK: - InventarioHeaderView (Resumen visual del camión — mejorado)
struct InventarioHeaderView: View {
    @ObservedObject var vm: InventarioViewModel
    @State private var progressAnimated = false
    @State private var truckBounce = false

    var body: some View {
        VStack(spacing: 24) {
            // ─── Camión con anillo de progreso grande ───
            ZStack {
                // Anillo fondo
                Circle()
                    .stroke(Color.bimboIce, lineWidth: 10)
                    .frame(width: 120, height: 120)

                // Anillo progreso animado
                Circle()
                    .trim(from: 0, to: progressAnimated ? vm.porcentajeGlobal : 0)
                    .stroke(
                        LinearGradient.bimboHero,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3),
                               value: progressAnimated)

                // Ícono camión
                VStack(spacing: 2) {
                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Color.bimboBlue)
                        .scaleEffect(truckBounce ? 1.1 : 1.0)
                    
                    // Porcentaje
                    Text("\(Int(vm.porcentajeGlobal * 100))%")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Color.bimboNavy)
                }
            }
            .shadow(color: Color.bimboBlue.opacity(0.2), radius: 20, y: 8)

            // ─── Stats: botones grandes con iconos ───
            HStack(spacing: 10) {
                StatButton(
                    value: "\(vm.totalProductos)",
                    label: "Cargados",
                    icon: "shippingbox.fill",
                    color: Color.bimboBlue
                )
                StatButton(
                    value: "\(vm.totalEntregados)",
                    label: "Entregados",
                    icon: "checkmark.circle.fill",
                    color: Color.bimboSuccessGreen
                )
                StatButton(
                    value: "\(vm.totalRestantes)",
                    label: "Restantes",
                    icon: "cube.fill",
                    color: Color.bimboWarningOrange
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .onAppear {
            progressAnimated = true
        }
        .onChange(of: vm.totalEntregados) { _, _ in
            // Bounce the truck
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                truckBounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                truckBounce = false
            }
            // Re-trigger progress
            progressAnimated = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.8)) {
                    progressAnimated = true
                }
            }
        }
    }
}

// MARK: - StatButton (botón grande con ícono prominente)
private struct StatButton: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            // Ícono grande
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
            }
            
            // Número
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color.bimboNavy)
                .contentTransition(.numericText())
            
            // Label
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: color.opacity(0.08), radius: 8, y: 4)
    }
}
