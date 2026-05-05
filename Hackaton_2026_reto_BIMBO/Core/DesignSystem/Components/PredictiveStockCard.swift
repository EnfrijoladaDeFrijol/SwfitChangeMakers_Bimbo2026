import SwiftUI

struct PredictiveStockCard: View {
    let item: StockSugerido
    var showAlert: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail del producto
            if item.producto.tieneImagen {
                Image(item.producto.imagenAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else if showAlert {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.alertAmber)
                    .frame(width: 44)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.bimboBlue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(Color.bimboBlue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.producto.nombre)
                    .font(.productName)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(item.razon)
                    .font(.badgeLabel)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()

            Text("\(item.cantidad)")
                .font(.stockCount)
                .foregroundStyle(showAlert ? Color.alertAmber : Color.bimboNavy)
        }
        .padding(AppConstants.cardPadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius, style: .continuous))
        .overlay(
            showAlert ?
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius, style: .continuous)
                .stroke(Color.alertAmber, lineWidth: 2) : nil
        )
    }
}
