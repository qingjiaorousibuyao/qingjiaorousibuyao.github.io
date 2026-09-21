import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack { EmptyStageView(title: "首页") }
                .tabItem { Label("首页", systemImage: "house") }
            NavigationStack { ContactListView() }
                .tabItem { Label("联系人", systemImage: "person.2") }
            NavigationStack { EmptyStageView(title: "空间") }
                .tabItem { Label("空间", systemImage: "square.grid.2x2") }
            NavigationStack { ProfileView() }
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .tint(AppPalette.accent)
    }
}

private struct EmptyStageView: View {
    let title: String
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PaperBackground())
            .navigationTitle(title)
    }
}
