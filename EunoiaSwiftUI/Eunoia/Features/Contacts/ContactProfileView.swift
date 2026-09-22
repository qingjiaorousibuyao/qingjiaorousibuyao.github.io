import SwiftData
import SwiftUI
import UIKit

private enum ContactProfileTab: String, CaseIterable, Hashable { case posts = "动态", album = "相册", letters = "信件", about = "关于" }

struct ContactProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var contact: Contact
    @State private var tab: ContactProfileTab = .posts
    @State private var editing = false
    @State private var deleting = false

    var body: some View {
        ZStack { EunoiaTheme.pageGradient.ignoresSafeArea(); ScrollView { VStack(spacing: 18) { hero; actions; infoCard; tabBar; tabContent }.padding(.bottom, 30) } }
            .toolbar(.hidden, for: .navigationBar).hidesEunoiaTabBar()
            .navigationDestination(isPresented: $editing) { ContactFormView(contact: contact) }
            .confirmationDialog("删除联系人？", isPresented: $deleting, titleVisibility: .visible) { Button("删除", role: .destructive) { context.delete(contact); try? context.save(); dismiss() }; Button("取消", role: .cancel) { } } message: { Text("联系人将从列表移除；独立的动态数据不会被删除。") }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            Group { if let data = MediaStore.imageData(path: contact.profileBackgroundPath), let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() } else { LinearGradient(colors: [EunoiaTheme.accentSoft, EunoiaTheme.background], startPoint: .top, endPoint: .bottom) } }.frame(height: 350).clipped()
            LinearGradient(colors: [.clear, EunoiaTheme.background.opacity(0.94)], startPoint: .center, endPoint: .bottom)
            HStack { Button { dismiss() } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle()) }; Spacer(); Menu { Button("编辑联系人", systemImage: "pencil") { editing = true }; Button("删除联系人", systemImage: "trash", role: .destructive) { deleting = true } } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle()) } }.padding(.horizontal, 16).padding(.top, 8)
            VStack(spacing: 9) { Spacer(); ContactAvatar(path: contact.avatarPath, size: 104); Text(contact.nickname).font(.title.bold()); Text(contact.signature.nilIfBlank ?? "未设置").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).lineLimit(2) }.padding(.horizontal, 30).padding(.bottom, 22)
        }.frame(height: 350)
    }

    private var actions: some View {
        HStack(spacing: 10) {
            NavigationLink { ContactChatView(contact: contact) } label: { ActionTile(icon: "bubble.left", title: "发消息") }
            NavigationLink { LetterPlaceholderView(contact: contact) } label: { ActionTile(icon: "envelope", title: "发信件") }
            Button { contact.isFavorite.toggle(); try? context.save() } label: { ActionTile(icon: contact.isFavorite ? "heart.fill" : "heart", title: "特别关心", active: contact.isFavorite) }
        }.padding(.horizontal, 20).buttonStyle(.plain)
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            InfoRow(icon: "person", label: "昵称", value: contact.nickname, action: { editing = true }); Divider()
            InfoRow(icon: "tag", label: "分组", value: contact.group.title, action: { editing = true }); Divider()
            InfoRow(icon: "mappin.and.ellipse", label: "地区", value: contact.region.nilIfBlank ?? "未设置", action: { editing = true }); Divider()
            InfoRow(icon: "text.quote", label: "个性签名", value: contact.signature.nilIfBlank ?? "未设置", action: { editing = true })
        }.softCard().padding(.horizontal, 20)
    }

    private var tabBar: some View {
        HStack { ForEach(ContactProfileTab.allCases, id: \.self) { item in Button { tab = item } label: { VStack(spacing: 7) { Image(systemName: item.icon); Text(item.rawValue).font(.subheadline); Capsule().fill(tab == item ? EunoiaTheme.accent : Color.clear).frame(width: 30, height: 3) }.frame(maxWidth: .infinity).foregroundStyle(tab == item ? EunoiaTheme.accent : Color.secondary) } } }.padding(.horizontal, 12).padding(.top, 12).softCard().padding(.horizontal, 20)
    }

    @ViewBuilder private var tabContent: some View {
        switch tab {
        case .posts: EmptyStateView(icon: "square.stack", title: "还没有动态", message: "动态数据迁移后，这里会显示该联系人的真实动态。")
        case .album: EmptyStateView(icon: "photo.on.rectangle", title: "还没有照片", message: "联系人动态中的真实图片会汇总在这里。")
        case .letters: VStack(spacing: 10) { ContactAvatar(path: contact.avatarPath, size: 70); Text(contact.nickname).font(.headline); Text("还没有信件").foregroundStyle(.secondary); NavigationLink("写一封信") { LetterPlaceholderView(contact: contact) }.buttonStyle(.borderedProminent).tint(EunoiaTheme.accent) }.padding(30)
        case .about: VStack(alignment: .leading, spacing: 16) { ContactAvatar(path: contact.avatarPath, size: 76).frame(maxWidth: .infinity); AboutRow(label: "昵称", value: contact.nickname); AboutRow(label: "个性签名", value: contact.signature.nilIfBlank ?? "未设置"); AboutRow(label: "分组", value: contact.group.title); AboutRow(label: "地区", value: contact.region.nilIfBlank ?? "未设置"); AboutRow(label: "创建时间", value: contact.createdAt.formatted(date: .long, time: .omitted)) }.padding(20).softCard().padding(.horizontal, 20)
        }
    }
}

private extension ContactProfileTab { var icon: String { switch self { case .posts: "square.stack"; case .album: "photo"; case .letters: "envelope"; case .about: "doc.text" } } }
private struct ActionTile: View { let icon: String; let title: String; var active = false; var body: some View { VStack(spacing: 7) { Image(systemName: icon).font(.title2); Text(title).font(.subheadline.weight(.semibold)) }.foregroundStyle(active ? EunoiaTheme.accent : Color.primary).frame(maxWidth: .infinity, minHeight: 88).softCard() } }
private struct InfoRow: View { let icon: String; let label: String; let value: String; let action: () -> Void; var body: some View { Button(action: action) { HStack(spacing: 12) { Image(systemName: icon).foregroundStyle(.secondary).frame(width: 24); Text(label).foregroundStyle(.secondary).frame(width: 72, alignment: .leading); Text(value).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }.frame(minHeight: 62).padding(.horizontal, 14) }.buttonStyle(.plain) } }
private struct AboutRow: View { let label: String; let value: String; var body: some View { VStack(alignment: .leading, spacing: 4) { Text(label).font(.caption).foregroundStyle(.secondary); Text(value) } } }

struct LetterPlaceholderView: View {
    let contact: Contact
    var body: some View { VStack(spacing: 12) { ContactAvatar(path: contact.avatarPath, size: 76); Text(contact.nickname).font(.title3.bold()); EmptyStateView(icon: "envelope", title: "信件功能正在准备中", message: "后续阶段将在这里完成写信与信件列表。") }.navigationTitle("信件").navigationBarTitleDisplayMode(.inline).hidesEunoiaTabBar() }
}
