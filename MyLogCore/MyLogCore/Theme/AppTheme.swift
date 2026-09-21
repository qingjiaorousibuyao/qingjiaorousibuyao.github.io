import SwiftUI

enum AppPalette {
    static let accent = Color(red: 0.56, green: 0.48, blue: 0.82)
    static let pink = Color(red: 0.92, green: 0.58, blue: 0.67)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.94)
    static let palePurple = Color(red: 0.95, green: 0.92, blue: 0.99)
}

struct PaperBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppPalette.cream, Color(red: 1, green: 0.93, blue: 0.95), AppPalette.palePurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct SoftCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.7), lineWidth: 0.8))
            .shadow(color: AppPalette.accent.opacity(0.1), radius: 14, y: 6)
    }
}

extension View {
    func softCard() -> some View { modifier(SoftCard()) }
}
