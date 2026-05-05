import SwiftUI

struct GlassBottomSheet<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            content
                .padding(.horizontal, AppConstants.cardPadding)
                .padding(.bottom, 32)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, y: -4)
    }
}

// Modifier para presentar GlassBottomSheet como overlay anclado al fondo
extension View {
    func glassSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        self.overlay(alignment: .bottom) {
            if isPresented.wrappedValue {
                GlassBottomSheet(content: content)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isPresented.wrappedValue)
                    .padding(.horizontal, 8)
            }
        }
    }
}
