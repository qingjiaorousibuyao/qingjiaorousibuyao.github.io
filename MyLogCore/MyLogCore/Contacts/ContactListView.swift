import SwiftData
import SwiftUI

struct ContactListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @Query private var messages: [ChatMessage]
    @State private var creating = false
    @State private var editing: Contact?
    @State private var deleting: Contact?

    var body: some View {
        Group {
            if contacts.isEmpty {
                ContentUnavailableView("还没有联系人", systemImage: "person.crop.circle.badge.plus", description: Text("添加一个重要的人，把关于对方的资料留在这里。"))
            } else {
                List(contacts) { contact in
                    NavigationLink { ChatView(initialContact: contact) } label: { row(contact) }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(allowsFullSwipe: false) {
                            Button("删除", systemImage: "trash", role: .destructive) { deleting = contact }
                            Button("编辑", systemImage: "pencil") { editing = contact }.tint(.blue)
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PaperBackground())
        .navigationTitle("联系人")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { creating = true } label: { Image(systemName: "plus") } } }
        .sheet(isPresented: $creating) { ContactEditorView() }
        .sheet(item: $editing) { ContactEditorView(contact: $0) }
        .confirmationDialog("删除这个联系人？", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("删除", role: .destructive) { if let deleting { delete(deleting) }; deleting = nil }
            Button("取消", role: .cancel) { deleting = nil }
        } message: { Text("联系人资料、聊天记录及本地媒体会一并删除。") }
    }

    private func row(_ contact: Contact) -> some View {
        HStack(spacing: 14) {
            ContactAvatar(path: contact.avatarPath, size: 58)
            VStack(alignment: .leading, spacing: 5) {
                Text(contact.name).font(.headline)
                Text(contact.bio?.nonBlank ?? "还没有简介").font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 8)
        }
        .padding(14)
        .softCard()
    }

    private func delete(_ contact: Contact) {
        messages.filter { $0.contactID == contact.id }.forEach {
            MediaStore.remove(path: $0.imagePath)
            MediaStore.remove(path: $0.audioPath)
            context.delete($0)
        }
        [contact.avatarPath, contact.coverPath, contact.chatBackgroundPath].forEach(MediaStore.remove)
        context.delete(contact)
        try? context.save()
    }
}
