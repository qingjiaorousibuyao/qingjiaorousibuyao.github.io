import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var tint: Color
    var tintStrength: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape
                    .fill(.thinMaterial)
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.18),
                                    tint.opacity(tintStrength),
                                    tint.opacity(tintStrength * 0.45),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .overlay {
                        shape.fill(
                            RadialGradient(
                                colors: [.white.opacity(0.18), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 90
                            )
                        )
                    }
                    .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.82), .white.opacity(0.18), tint.opacity(0.30), .white.opacity(0.48)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
                    .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.36), .clear, .black.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.7
                    )
                    .padding(1.5)
                    .allowsHitTesting(false)
            }
            .clipShape(shape)
            .shadow(color: .white.opacity(0.13), radius: 2, x: -1, y: -1)
            .shadow(color: .black.opacity(0.14), radius: 10, y: 5)
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
