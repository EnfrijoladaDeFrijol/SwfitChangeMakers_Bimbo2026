import SwiftUI

struct DynamicContextBanner: View {
    let evento: EventoLocal
    let onAnadir:  () -> Void
    let onIgnorar: () -> Void

    @State private var expanded = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title3.bold())
                .foregroundStyle(Color.bimboSky)

            VStack(alignment: .leading, spacing: 2) {
                Text(evento.descripcion)
                    .font(.sectionTitle)
                    .foregroundStyle(.white)
                    .lineLimit(expanded ? nil : 1)
                if expanded {
                    Text(evento.fecha)
                        .font(.badgeLabel)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .onTapGesture { withAnimation(.spring()) { expanded.toggle() } }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onAnadir) {
                    Text("Añadir")
                        .font(.badgeLabel.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.bimboBlue)
                        .clipShape(Capsule())
                }
                .minTapTarget()

                Button(action: onIgnorar) {
                    Text("Ignorar")
                        .font(.badgeLabel)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                }
                .minTapTarget()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.95))
        .background(Color.bimboNavy.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
