import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var tint: Color
    var tintStrength: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(.regularMaterial, in: shape)
            .background(tint.opacity(tintStrength), in: shape)
            .overlay {
                shape.stroke(.white.opacity(0.42), lineWidth: 0.7)
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.68), .white.opacity(0.08), tint.opacity(0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                    .padding(1)
            }
            .overlay(alignment: .topLeading) {
                shape
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.20), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            }
            .clipShape(shape)
            .shadow(color: .black.opacity(0.09), radius: 9, y: 4)
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    var tint: Color = .clear
    var cornerRadius: CGFloat = 24

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .liquidGlass(cornerRadius: cornerRadius, tint: tint, tintStrength: configuration.isPressed ? 0.18 : 0.10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension View {
    func liquidGlass(
        cornerRadius: CGFloat,
        tint: Color = .clear,
        tintStrength: Double = 0.10
    ) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, tint: tint, tintStrength: tintStrength))
    }
}
