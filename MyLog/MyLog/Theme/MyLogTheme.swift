import SwiftUI

enum MyLogTheme {
    static let purple = Color(red: 0.56, green: 0.48, blue: 0.82)
    static let pink = Color(red: 0.92, green: 0.58, blue: 0.67)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.94)
    static let palePurple = Color(red: 0.95, green: 0.92, blue: 0.99)
    static let divider = Color.primary.opacity(0.08)
}

enum AppThemePreset: String, CaseIterable, Identifiable, Codable {
    case creamPink, lavender, monochrome

    var id: String { rawValue }
    var title: String {
        switch self {
        case .creamPink: "奶油粉"
        case .lavender: "淡紫"
        case .monochrome: "黑白"
        }
    }
}

private struct ThemeConfiguration: Codable {
    var preset: AppThemePreset
    var accentIndex: Int
    var cardOpacity: Double
    var homeBackgroundFilename: String?
    var splashFilename: String?
    var showsCustomSplash: Bool
}

final class ThemeSettings: ObservableObject {
    @Published var preset: AppThemePreset { didSet { persistIfReady() } }
    @Published var accentIndex: Int { didSet { persistIfReady() } }
    @Published var cardOpacity: Double { didSet { persistIfReady() } }
    @Published var showsCustomSplash: Bool { didSet { persistIfReady() } }
    @Published private(set) var homeBackgroundData: Data?
    @Published private(set) var splashData: Data?

    private var homeBackgroundFilename: String?
    private var splashFilename: String?
    private var isRestoring = true
    private static let configurationFilename = "theme-settings.json"

    init() {
        if let saved = PersistentSettingsStore.load(ThemeConfiguration.self, from: Self.configurationFilename) {
            preset = saved.preset
            accentIndex = saved.accentIndex
            cardOpacity = min(max(saved.cardOpacity, 0), 1)
            homeBackgroundFilename = saved.homeBackgroundFilename
            splashFilename = saved.splashFilename
            showsCustomSplash = saved.showsCustomSplash
        } else {
            let defaults = UserDefaults.standard
            preset = AppThemePreset(rawValue: defaults.string(forKey: "theme.preset") ?? "") ?? .creamPink
            accentIndex = defaults.object(forKey: "theme.accentIndex") as? Int ?? 0
            cardOpacity = min(max(defaults.object(forKey: "theme.cardOpacity") as? Double ?? 0.78, 0), 1)
            homeBackgroundFilename = nil
            splashFilename = nil
            showsCustomSplash = false

            if let legacyBackground = defaults.data(forKey: "theme.homeBackground") {
                homeBackgroundFilename = PersistentSettingsStore.saveImage(legacyBackground, filename: "home-background.jpg", maxDimension: 2400)
            }
        }

        homeBackgroundData = PersistentSettingsStore.loadImage(filename: homeBackgroundFilename)
        splashData = PersistentSettingsStore.loadImage(filename: splashFilename)
        isRestoring = false
        persist()
    }

    var accent: Color {
        if preset == .monochrome { return .primary }
        let colors: [Color] = [MyLogTheme.purple, MyLogTheme.pink, .indigo, .mint]
        return colors[min(max(accentIndex, 0), colors.count - 1)]
    }

    var backgroundColors: [Color] {
        switch preset {
        case .creamPink: [MyLogTheme.cream, Color(red: 1, green: 0.93, blue: 0.95), MyLogTheme.palePurple]
        case .lavender: [Color(red: 0.96, green: 0.94, blue: 1), Color(red: 0.91, green: 0.88, blue: 0.98)]
        case .monochrome: [Color(uiColor: .systemBackground), Color(uiColor: .secondarySystemBackground)]
        }
    }

    func apply(_ newPreset: AppThemePreset) {
        preset = newPreset
        accentIndex = newPreset == .creamPink ? 0 : newPreset == .lavender ? 2 : 0
    }

    func setHomeBackground(_ data: Data?) {
        if let data {
            guard let filename = PersistentSettingsStore.saveImage(data, filename: "home-background.jpg", maxDimension: 2400) else { return }
            homeBackgroundFilename = filename
            homeBackgroundData = PersistentSettingsStore.loadImage(filename: filename)
        } else {
            PersistentSettingsStore.removeImage(filename: homeBackgroundFilename)
            homeBackgroundFilename = nil
            homeBackgroundData = nil
        }
        persist()
    }

    func setSplashImage(_ data: Data?) {
        if let data {
            guard let filename = PersistentSettingsStore.saveImage(data, filename: "custom-splash.jpg", maxDimension: 2600) else { return }
            splashFilename = filename
            splashData = PersistentSettingsStore.loadImage(filename: filename)
        } else {
            PersistentSettingsStore.removeImage(filename: splashFilename)
            splashFilename = nil
            splashData = nil
            showsCustomSplash = false
        }
        persist()
    }

    private func persistIfReady() {
        guard !isRestoring else { return }
        persist()
    }

    private func persist() {
        let configuration = ThemeConfiguration(
            preset: preset,
            accentIndex: accentIndex,
            cardOpacity: cardOpacity,
            homeBackgroundFilename: homeBackgroundFilename,
            splashFilename: splashFilename,
            showsCustomSplash: showsCustomSplash
        )
        PersistentSettingsStore.save(configuration, to: Self.configurationFilename)
    }
}

struct PaperBackground: View {
    @EnvironmentObject private var theme: ThemeSettings
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(colors: colorScheme == .dark ? [.black, Color(white: 0.10)] : theme.backgroundColors,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            if let data = theme.homeBackgroundData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().opacity(colorScheme == .dark ? 0.18 : 0.24)
            }
            Canvas { context, size in
                for index in 0..<12 {
                    let x = CGFloat((index * 83) % 100) / 100 * size.width
                    let y = CGFloat((index * 47 + 13) % 100) / 100 * size.height
                    context.opacity = colorScheme == .dark ? 0.05 : 0.08
                    context.draw(Text("♡").font(.system(size: CGFloat(14 + index % 4 * 4))).foregroundStyle(theme.accent), at: CGPoint(x: x, y: y))
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct SoftCardModifier: ViewModifier {
    @EnvironmentObject private var theme: ThemeSettings
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color(uiColor: colorScheme == .dark ? .secondarySystemBackground : .systemBackground)
                .opacity(theme.cardOpacity), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(colorScheme == .dark ? .white.opacity(0.10) : .white.opacity(0.72), lineWidth: 0.8)
                .allowsHitTesting(false))
            .shadow(color: theme.accent.opacity(colorScheme == .dark ? 0.06 : 0.10), radius: 14, y: 6)
    }
}

extension View {
    func softCard() -> some View { modifier(SoftCardModifier()) }
}
