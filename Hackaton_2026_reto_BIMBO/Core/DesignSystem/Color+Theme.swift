import SwiftUI
import UIKit

// MARK: - Hex initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Bimbo Design System Palette — Azul Dominante / Minimalista
extension Color {
    // --- Azul principal (acento dominante) ---
    static let bimboBlue         = Color(hex: "#0A5EB8")  // Azul Bimbo — acento principal
    static let bimboNavy         = Color(hex: "#0D1B3E")  // Azul profundo — títulos, textos hero
    static let bimboNavyLight    = Color(hex: "#1A4E8A")  // Variante intermedia
    static let bimboSky          = Color(hex: "#4DA3E8")  // Azul cielo — gradientes, highlights
    static let bimboIce          = Color(hex: "#E8F1FA")  // Azul hielo — fondos sutiles (light)

    // --- Rojo solo para danger/destructivo (uso mínimo) ---
    static let bimboRed          = Color(hex: "#E21221")  // Solo para destructivo/alertas graves
    static let bimboDangerRed    = Color(hex: "#FF3B30")  // Error / acción destructiva

    // --- Semánticos ---
    static let bimboWarningOrange = Color(hex: "#F5A623") // Alertas de caducidad (Ámbar suave)
    static let bimboSuccessGreen  = Color(hex: "#34C759") // Confirmaciones exitosas
    static let bimboGold         = Color(hex: "#FFD60A")  // Dorado para logros / badges

    // --- Neutros ---
    static let bimboCream        = Color(hex: "#F7FAFD")  // Fondo frío alternativo (light mode)

    // --- Alias retrocompatibles ---
    static let alertAmber        = bimboWarningOrange
    static let successGreen      = bimboSuccessGreen
    static let dangerRed         = bimboDangerRed

    // --- Superficies adaptativas (Dark/Light Mode) ---
    static let cardSurface       = Color(UIColor.secondarySystemBackground)
    static let appBG             = Color(UIColor.systemBackground)
}

// MARK: - Gradients — Azul dominante
extension LinearGradient {
    /// Gradiente hero principal: azul profundo → azul cielo
    static let bimboHero = LinearGradient(
        colors: [Color.bimboBlue, Color.bimboSky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// Gradiente navy oscuro
    static let bimboNavyGradient = LinearGradient(
        colors: [Color.bimboNavy, Color.bimboNavyLight],
        startPoint: .top,
        endPoint: .bottom
    )
    /// Gradiente éxito
    static let successGradient = LinearGradient(
        colors: [Color.bimboSuccessGreen.opacity(0.85), Color.bimboSuccessGreen],
        startPoint: .top,
        endPoint: .bottom
    )
    /// Fondo sutil azulado
    static let warmBackground = LinearGradient(
        colors: [Color.bimboCream, Color.appBG],
        startPoint: .top,
        endPoint: .bottom
    )
    /// Gradiente para micrófono activo
    static let micActiveGradient = LinearGradient(
        colors: [Color.bimboBlue, Color.bimboNavy],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - View helpers
extension View {
    func navyTitle()    -> some View { self.font(.largeTitle.bold()).foregroundStyle(Color.bimboNavy) }
    func blueAccent()   -> some View { self.foregroundStyle(Color.bimboBlue) }
    func redAccent()    -> some View { self.foregroundStyle(Color.bimboDangerRed) }
    func minTapTarget() -> some View { self.frame(minWidth: 44, minHeight: 44) }
}

// MARK: - Demo button (para testing del tema)
struct BimboThemePreviewButton: View {
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2.bold())
                Text("Guardar Punto")
                    .font(.title2.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(Color.bimboBlue)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.bimboBlue.opacity(0.4), radius: 10, y: 6)
            .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Botón Bimbo") {
    ZStack {
        Color.appBG.ignoresSafeArea()
        VStack(spacing: 20) {
            BimboThemePreviewButton()
            HStack(spacing: 12) {
                ForEach([Color.bimboBlue, Color.bimboNavy, Color.bimboSky, Color.bimboSuccessGreen, Color.bimboWarningOrange], id: \.self) { c in
                    Circle().fill(c).frame(width: 44, height: 44)
                        .shadow(color: c.opacity(0.4), radius: 4)
                }
            }
        }
    }
}
