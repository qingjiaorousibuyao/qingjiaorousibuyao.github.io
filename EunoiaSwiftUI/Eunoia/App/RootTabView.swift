import SwiftUI

enum AppTab: Hashable { case home, chat, publish, space, profile }

struct RootTabView: View {
    @State private var selection: AppTab = .chat
    @State private var showsBar = true
    var body: some View {
        Group {
            switch selection {
            case .home: PlaceholderView(title: "首页", icon: "house", message: "首页将在后续阶段迁移。")
            case .chat: NavigationStack { ContactsHomeView() }
            case .publish: PlaceholderView(title: "发布", icon: "plus.circle.fill", message: "发布动态将在后续阶段迁移。")
            case .space: PlaceholderView(title: "空间", icon: "sparkles", message: "空间将在后续阶段迁移。")
            case .profile: PlaceholderView(title: "我的", icon: "person", message: "用户资料将在后续阶段迁移。")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { if showsBar { EunoiaTabBar(selection: $selection) } }
        .onPreferenceChange(EunoiaTabBarVisibilityKey.self) { showsBar = $0 }
    }
}

private struct EunoiaTabBar: View {
    @Binding var selection: AppTab
    var body: some View { HStack { item(.home, "house", "首页"); item(.chat, "bubble.left.and.bubble.right", "聊天"); Button { selection = .publish } label: { Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white).frame(width: 60, height: 60).background(EunoiaTheme.accent, in: Circle()).shadow(color: EunoiaTheme.accent.opacity(0.24), radius: 10, y: 4) }.frame(maxWidth: .infinity); item(.space, "sparkles", "空间"); item(.profile, "person", "我的") }.padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 4).background(.ultraThinMaterial).overlay(alignment: .top) { Divider() } }
    private func item(_ tab: AppTab, _ icon: String, _ title: String) -> some View { Button { selection = tab } label: { VStack(spacing: 3) { Image(systemName: icon); Text(title).font(.caption) }.foregroundStyle(selection == tab ? EunoiaTheme.accent : Color.secondary).frame(maxWidth: .infinity, minHeight: 52).background(selection == tab ? EunoiaTheme.accentSoft : Color.clear, in: RoundedRectangle(cornerRadius: 16)) } }
}

private struct EunoiaTabBarVisibilityKey: PreferenceKey { static var defaultValue = true; static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value && nextValue() } }
extension View { func hidesEunoiaTabBar() -> some View { preference(key: EunoiaTabBarVisibilityKey.self, value: false) } }

struct PlaceholderView: View {
    let title: String; let icon: String; let message: String
    var body: some View { ZStack { EunoiaTheme.pageGradient.ignoresSafeArea(); EmptyStateView(icon: icon, title: title, message: message) } }
}
