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

private struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { TimelineView() }
                .background(InteractivePopGestureSupport())
                .tabItem { Label("首页", systemImage: "house") }
            NavigationStack { CalendarView() }
                .background(InteractivePopGestureSupport())
                .tabItem { Label("日历", systemImage: "calendar") }
            NavigationStack { SearchView() }
                .background(InteractivePopGestureSupport())
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
            NavigationStack { ContactListView() }
                .background(InteractivePopGestureSupport())
                .tabItem { Label("联系人", systemImage: "person.2") }
            NavigationStack { ProfileView() }
                .background(InteractivePopGestureSupport())
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
    }
}

private struct InteractivePopGestureSupport: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        InteractivePopInstaller()
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) { }

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

        private func installGestureSupport() {
            guard let navigationController = self.navigationController ?? parent?.navigationController,
                  let gesture = navigationController.interactivePopGestureRecognizer else { return }
            installedNavigationController = navigationController
            gesture.delegate = self
            gesture.isEnabled = true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (installedNavigationController?.viewControllers.count ?? 0) > 1
        }
    }
}
