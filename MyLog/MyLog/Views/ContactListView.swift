import SwiftUI
import SwiftData

struct ContactListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @State private var isCreating = false
    @State private var contactToDelete: Contact?

    var body: some View {
        ZStack {
            PaperBackground()
            if contacts.isEmpty {
                ContentUnavailableView(
                    "还没有联系人",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("添加一个重要的人，把关于对方的资料留在这里。")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(contacts) { contact in
                            NavigationLink(value: contact.id) {
                                ContactRow(contact: contact)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("删除联系人", systemImage: "trash", role: .destructive) {
                                    contactToDelete = contact
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("联系人")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isCreating = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("新建联系人")
            }
        }
        .navigationDestination(for: UUID.self) { id in
            if let contact = contacts.first(where: { $0.id == id }) {
                ContactDetailView(contact: contact)
            } else {
                ContentUnavailableView("联系人不存在", systemImage: "person.slash")
            }
        }
        .sheet(isPresented: $isCreating) { ContactEditorView() }
        .confirmationDialog("删除这个联系人？", isPresented: Binding(
            get: { contactToDelete != nil },
            set: { if !$0 { contactToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let contactToDelete { delete(contactToDelete) }
                contactToDelete = nil
            }
            Button("取消", role: .cancel) { contactToDelete = nil }
        } message: {
            Text("联系人资料和本地头像、封面将被删除。现有日记不会受到影响。")
        }
    }

    private func delete(_ contact: Contact) {
        PersistentSettingsStore.removeImage(filename: contact.avatarFilename)
        PersistentSettingsStore.removeImage(filename: contact.coverImageFilename)
        context.delete(contact)
        try? context.save()
    }
}

private struct ContactRow: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 14) {
            ContactAvatar(filename: contact.avatarFilename, size: 58)
            VStack(alignment: .leading, spacing: 5) {
                Text(contact.name).font(.headline)
                Text(contact.bio?.nilIfBlank ?? "还没有简介")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(14)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .softCard()
    }
}

struct ContactAvatar: View {
    let filename: String?
    var size: CGFloat

    var body: some View {
        Group {
            if let data = PersistentSettingsStore.loadImage(filename: filename), let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Circle().fill(MyLogTheme.palePurple)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(MyLogTheme.purple))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
    }
}

extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
