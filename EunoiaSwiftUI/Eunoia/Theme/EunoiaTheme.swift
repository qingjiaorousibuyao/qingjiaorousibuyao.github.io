import SwiftUI

enum EunoiaTheme {
    static let background = Color(red: 1, green: 0.973, blue: 0.973)
    static let surface = Color.white.opacity(0.82)
    static let muted = Color(red: 0.988, green: 0.933, blue: 0.941)
    static let accent = Color(red: 0.808, green: 0.431, blue: 0.49)
    static let accentSoft = Color(red: 0.973, green: 0.867, blue: 0.882)
    static let divider = Color(red: 0.953, green: 0.902, blue: 0.91)
    static let pageGradient = LinearGradient(colors: [background, Color(red: 1, green: 0.94, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct SoftCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .background(EunoiaTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.72), lineWidth: 0.8))
            .shadow(color: EunoiaTheme.accent.opacity(0.09), radius: 14, y: 6)
    }
}

extension View { func softCard() -> some View { modifier(SoftCardModifier()) } }
extension String { var nilIfBlank: String? { let value = trimmingCharacters(in: .whitespacesAndNewlines); return value.isEmpty ? nil : value } }
