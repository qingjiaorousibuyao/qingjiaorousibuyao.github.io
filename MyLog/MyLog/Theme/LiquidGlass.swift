import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var tint: Color
    var tintStrength: Double
    var isInteractive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular
                    .tint(tintStrength > 0 ? tint.opacity(tintStrength) : nil)
                    .interactive(isInteractive),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            fallback(content: content)
        }
    }

    private func fallback(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(.thinMaterial, in: shape)
            .background(tint.opacity(tintStrength), in: shape)
            .overlay(shape.stroke(.white.opacity(0.45), lineWidth: 0.8).allowsHitTesting(false))
            .clipShape(shape)
            .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    var tint: Color = .clear
    var cornerRadius: CGFloat = 24

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .liquidGlass(
                cornerRadius: cornerRadius,
                tint: tint,
                tintStrength: configuration.isPressed ? 0.18 : 0.10,
                isInteractive: true
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension View {
    func liquidGlass(
        cornerRadius: CGFloat,
        tint: Color = .clear,
        tintStrength: Double = 0.10,
        isInteractive: Bool = false
    ) -> some View {
        modifier(LiquidGlassModifier(
            cornerRadius: cornerRadius,
            tint: tint,
            tintStrength: tintStrength,
            isInteractive: isInteractive
        ))
    }
}
