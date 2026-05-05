import SwiftUI

struct AlertaCaducidadView: View {
    let items: [StockSugerido]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Caducidad Próxima", systemImage: "exclamationmark.triangle.fill")
                .font(.sectionTitle)
                .foregroundStyle(Color.alertAmber)

            ForEach(items, id: \.producto.id) { item in
                HStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.alertAmber)
                        .font(.title2)
                        .frame(width: 32)

                    Text(item.producto.nombre)
                        .font(.productName)
                        .lineLimit(1)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(item.cantidad)")
                            .font(.stockCount)
                            .foregroundStyle(Color.alertAmber)
                        Text("\(item.producto.diasCaducidad)d")
                            .font(.badgeLabel)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color.alertAmber.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.alertAmber.opacity(0.4), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(AppConstants.cardPadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius, style: .continuous))
    }
}
