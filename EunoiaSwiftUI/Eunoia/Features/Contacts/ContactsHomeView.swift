import SwiftData
import SwiftUI

private enum ContactSection: String, CaseIterable, Hashable { case conversations = "对话", letters = "信件", screenings = "放映", album = "相册" }

struct ContactsHomeView: View {
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @Query(sort: \ChatMessage.createdAt) private var messages: [ChatMessage]
    @State private var section: ContactSection = .conversations
    @State private var query = ""
    @State private var searching = false

    private var filteredContacts: [Contact] {
        guard let term = query.nilIfBlank else { return contacts }
        let matchingChatIDs = Set(messages.compactMap { message in message.text?.localizedCaseInsensitiveContains(term) == true ? message.contactID : nil })
        return contacts.filter { $0.nickname.localizedCaseInsensitiveContains(term) || matchingChatIDs.contains($0.id) }
    }
    private var recentContacts: [Contact] {
        let latest = Dictionary(grouping: messages, by: \.contactID).compactMapValues { $0.max(by: { $0.createdAt < $1.createdAt }) }
        return contacts.filter { latest[$0.id] != nil }.sorted { (latest[$0.id]?.createdAt ?? .distantPast) > (latest[$1.id]?.createdAt ?? .distantPast) }
    }

    var body: some View {
        ZStack {
            EunoiaTheme.pageGradient.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    brandHeader
                    Picker("栏目", selection: $section) { ForEach(ContactSection.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                        .pickerStyle(.segmented).padding(6).softCard()
                    if section == .conversations { conversationContent } else { EmptyStateView(icon: "hourglass", title: section.rawValue, message: "功能正在准备中") }
                }.padding(20).padding(.bottom, 22)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .searchable(text: $query, isPresented: $searching, prompt: "搜索联系人或聊天内容")
    }

    private var brandHeader: some View {
        HStack { VStack(alignment: .leading, spacing: 2) { Text("Eunoia").font(.system(size: 34, weight: .light, design: .serif)).italic(); Text("A kinder place for my people.").font(.caption).foregroundStyle(.secondary) }; Spacer(); Button { searching = true } label: { Image(systemName: "magnifyingglass").font(.title2).frame(width: 44, height: 44) } }
    }

    @ViewBuilder private var conversationContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    NavigationLink { ContactFormView() } label: { ContactShortcut(title: "新建", path: nil, isNew: true) }
                    ForEach(filteredContacts) { contact in NavigationLink { ContactProfileView(contact: contact) } label: { ContactShortcut(title: contact.nickname, path: contact.avatarPath) } }
                }.padding(14)
            }.softCard()
            Text("最近会话").font(.headline)
            if recentContacts.isEmpty { Text("还没有会话，发送第一条消息后会显示在这里。").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(24) }
            else { VStack(spacing: 8) { ForEach(recentContacts) { contact in NavigationLink { ContactChatView(contact: contact) } label: { ConversationRow(contact: contact, message: messages.last { $0.contactID == contact.id }) } } } }
            Text("分组").font(.headline).padding(.top, 6)
            VStack(spacing: 0) {
                GroupLink(title: "所有联系人", icon: "person.2", count: contacts.count, filter: .all)
                Divider(); GroupLink(title: "特别关心", icon: "heart", count: contacts.filter(\.isFavorite).count, filter: .favorite)
                Divider(); GroupLink(title: "朋友", icon: "person.2.circle", count: contacts.filter { $0.group == .friends }.count, filter: .group(.friends))
                Divider(); GroupLink(title: "重要的人", icon: "calendar.badge.star", count: contacts.filter { $0.group == .important }.count, filter: .group(.important))
                Divider(); GroupLink(title: "未分组", icon: "folder", count: contacts.filter { $0.group == .ungrouped }.count, filter: .group(.ungrouped))
            }.padding(.horizontal, 14).softCard()
        }
    }
}

private struct ContactShortcut: View {
    let title: String; let path: String?; var isNew = false
    var body: some View { VStack(spacing: 6) { if isNew { RoundedRectangle(cornerRadius: 17).fill(EunoiaTheme.muted).frame(width: 56, height: 56).overlay(Image(systemName: "plus").font(.title2).foregroundStyle(EunoiaTheme.accent)) } else { ContactAvatar(path: path, size: 56) }; Text(title).font(.caption).lineLimit(1).frame(width: 66) }.foregroundStyle(.primary) }
}

private struct ConversationRow: View {
    let contact: Contact; let message: ChatMessage?
    var body: some View { HStack(spacing: 12) { ContactAvatar(path: contact.avatarPath, size: 50); VStack(alignment: .leading, spacing: 4) { Text(contact.nickname).font(.headline); Text(message?.text ?? message.map { $0.typeValue == .image ? "[图片]" : "[语音]" } ?? "").font(.subheadline).foregroundStyle(.secondary).lineLimit(1) }; Spacer(); if let date = message?.createdAt { Text(date, style: .time).font(.caption).foregroundStyle(.tertiary) } }.padding(14).softCard().foregroundStyle(.primary) }
}

enum ContactFilter: Hashable { case all, favorite, group(ContactGroup) }
private struct GroupLink: View {
    let title: String; let icon: String; let count: Int; let filter: ContactFilter
    var body: some View { NavigationLink { ContactGroupListView(title: title, filter: filter) } label: { HStack { Image(systemName: icon).frame(width: 30); Text(title); Spacer(); Text("\(count)").foregroundStyle(.secondary); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }.frame(minHeight: 58).foregroundStyle(.primary) } }
}
