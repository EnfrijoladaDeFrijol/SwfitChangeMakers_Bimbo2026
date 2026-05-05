import SwiftUI

struct AjusteManualView: View {
    @Binding var items: [StockSugerido]
    let onAjuste: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach($items, id: \.producto.id) { $item in
                            StockOverrideCard(item: $item, onAjuste: onAjuste)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 100)
                }

                // FAB confirmar al fondo
                VStack {
                    Spacer()
                    MassiveActionButton(
                        label: "Confirmar Stock",
                        icon: "checkmark.seal.fill",
                        color: Color.successGreen
                    ) { dismiss() }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .background(
                        LinearGradient(
                            colors: [Color.appBG.opacity(0), Color.appBG],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
            }
            .navigationTitle("Override Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Color.bimboNavy)
                }
            }
        }
    }
}

private struct StockOverrideCard: View {
    @Binding var item: StockSugerido
    let onAjuste: (String, Int) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.producto.nombre)
                        .font(.productName)
                        .foregroundStyle(.primary)
                    Text(item.razon)
                        .font(.badgeLabel)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            // Stepper masivo
            HStack(spacing: 24) {
                StepperButton(symbol: "minus", color: Color.bimboDangerRed) {
                    onAjuste(item.producto.id, -1)
                }

                Text("\(item.cantidad)")
                    .font(.stockCount)
                    .foregroundStyle(Color.bimboNavy)
                    .frame(minWidth: 80)
                    .multilineTextAlignment(.center)

                StepperButton(symbol: "plus", color: Color.successGreen) {
                    onAjuste(item.producto.id, +1)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AppConstants.cardPadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius, style: .continuous))
    }
}

#Preview {
    AjusteManualView(
        items: .constant(
            Producto.hardcoded.map { StockSugerido(producto: $0, cantidad: 6, razon: "Demo") }
        ),
        onAjuste: { _, _ in }
    )
}
