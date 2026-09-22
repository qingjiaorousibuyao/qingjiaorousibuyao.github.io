import SwiftUI

struct LaunchContainerView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            RootView()
            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.35)) { isShowingSplash = false }
        }
    }
}

struct SplashView: View {
    @EnvironmentObject private var theme: ThemeSettings

    var body: some View {
        Group {
            if theme.showsCustomSplash, let data = theme.splashData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                DefaultSplashArtwork()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }
}

struct DefaultSplashArtwork: View {
    @EnvironmentObject private var theme: ThemeSettings

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(theme.accent)
                Text("MyLog").font(.system(size: 42, weight: .semibold, design: .serif))
                Text("写给未来的自己").foregroundStyle(.secondary)
            }
        }
    }
}
