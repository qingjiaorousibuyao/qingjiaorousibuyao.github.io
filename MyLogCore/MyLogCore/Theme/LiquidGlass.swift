import SwiftUI

private struct LiquidGlassModifier: ViewModifier {
    let radius: CGFloat
    let tint: Color
    let strength: Double
    let interactive: Bool

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular.tint(strength > 0 ? tint.opacity(strength) : nil).interactive(interactive),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
        } else {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            content
                .background(.thinMaterial, in: shape)
                .background(tint.opacity(strength), in: shape)
                .overlay(shape.stroke(.white.opacity(0.45), lineWidth: 0.8))
                .clipShape(shape)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
    }
}

extension View {
    func liquidGlass(radius: CGFloat, tint: Color = .clear, strength: Double = 0.1, interactive: Bool = false) -> some View {
        modifier(LiquidGlassModifier(radius: radius, tint: tint, strength: strength, interactive: interactive))
    }
}

struct GlassButtonStyle: ButtonStyle {
    var tint: Color = .clear
    var radius: CGFloat = 22
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .liquidGlass(radius: radius, tint: tint, strength: configuration.isPressed ? 0.18 : 0.1, interactive: true)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
