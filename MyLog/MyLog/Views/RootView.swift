import SwiftUI

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
                .tabItem { Label("首页", systemImage: "house") }
            NavigationStack { CalendarView() }
                .tabItem { Label("日历", systemImage: "calendar") }
            NavigationStack { SearchView() }
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
            NavigationStack { ContactListView() }
                .tabItem { Label("联系人", systemImage: "person.2") }
            NavigationStack { ProfileView() }
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
    }
}
