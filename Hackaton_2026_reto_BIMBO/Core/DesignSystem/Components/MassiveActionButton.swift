import SwiftUI

struct MassiveActionButton: View {
    let label:  String
    let icon:   String
    let color:  Color
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2.bold())
                Text(label)
                    .font(.title2.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius, style: .continuous))
            .shadow(color: color.opacity(0.4), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// Stepper buttons para override de stock
struct StepperButton: View {
    let symbol: String
    let color:  Color
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
                .frame(width: AppConstants.stepperButtonSize,
                       height: AppConstants.stepperButtonSize)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
