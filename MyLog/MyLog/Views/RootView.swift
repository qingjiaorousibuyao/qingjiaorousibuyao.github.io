import SwiftUI
import UIKit

struct RootView: View {
    @AppStorage("requiresFaceID") private var requiresFaceID = false
    @State private var unlocked = false
    @EnvironmentObject private var theme: ThemeSettings

    var body: some View {
        Group {
            if !requiresFaceID || unlocked {
                MainTabView()
            } else {
                LockedView { unlocked = true }
            }
        }
        .tint(theme.accent)
        .task {
            guard requiresFaceID else { return }
            unlocked = await AppLock.authenticate()
        }
    }
}

private enum MainTab: Hashable { case home, chat, space, profile }

private struct MainTabView: View {
    @State private var selection: MainTab = .home
    @State private var composing = false

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { TimelineView().background(InteractivePopGestureSupport()) }.tag(MainTab.home)
            NavigationStack { ContactListView().background(InteractivePopGestureSupport()) }.tag(MainTab.chat)
            NavigationStack { EunoiaSpaceView().background(InteractivePopGestureSupport()) }.tag(MainTab.space)
            NavigationStack { ProfileView().background(InteractivePopGestureSupport()) }.tag(MainTab.profile)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { EunoiaTabBar(selection: $selection, composing: $composing) }
        .sheet(isPresented: $composing) { ComposeView() }
    }
}

private struct EunoiaSpaceView: View {
    var body: some View {
        ContentUnavailableView("空间", systemImage: "planet", description: Text("空间内容将在后续版本中完善。"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PaperBackground())
            .navigationTitle("空间")
    }
}

private struct EunoiaTabBar: View {
    @Binding var selection: MainTab
    @Binding var composing: Bool
    @EnvironmentObject private var theme: ThemeSettings

    var body: some View {
        HStack(spacing: 5) {
            item("首页", icon: "house.fill", tab: .home)
            item("聊天", icon: "bubble.left.and.bubble.right.fill", tab: .chat)
            Button { composing = true } label: {
                Image(systemName: "plus").font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 58, height: 58)
                    .background(MyLogTheme.pink, in: Circle())
                    .shadow(color: MyLogTheme.pink.opacity(0.32), radius: 10, y: 5)
            }
            .accessibilityLabel("发布")
            .offset(y: -10)
            item("空间", icon: "planet.fill", tab: .space)
            item("我的", icon: "person.fill", tab: .profile)
        }
        .padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 5)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider().opacity(0.35) }
    }

    private func item(_ title: String, icon: String, tab: MainTab) -> some View {
        Button { selection = tab } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(.caption2)
            }
            .foregroundStyle(selection == tab ? theme.accent : .secondary)
            .frame(maxWidth: .infinity).padding(.vertical, 7)
            .background(selection == tab ? MyLogTheme.pink.opacity(0.14) : .clear,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct InteractivePopGestureSupport: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        InteractivePopInstaller()
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        (controller as? InteractivePopInstaller)?.installGestureSupport()
    }

    private final class InteractivePopInstaller: UIViewController, UIGestureRecognizerDelegate {
        weak var installedNavigationController: UINavigationController?

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            installGestureSupport()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            installGestureSupport()
        }

        func installGestureSupport() {
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let navigationController = self.navigationController ?? self.parent?.navigationController,
                      let gesture = navigationController.interactivePopGestureRecognizer else { return }
                self.installedNavigationController = navigationController
                gesture.delegate = self
                gesture.isEnabled = true
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (installedNavigationController?.viewControllers.count ?? 0) > 1
        }
    }
}
