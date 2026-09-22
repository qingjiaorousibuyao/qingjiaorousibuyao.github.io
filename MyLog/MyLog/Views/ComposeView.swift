import SwiftUI
import SwiftData
import PhotosUI

struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var profile: ProfileSettings
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @State private var text: String
    @State private var selection: [PhotosPickerItem] = []
    @State private var photos: [Data]
    @State private var author: PostAuthorSelection
    @State private var location: String
    @State private var publishDate: Date
    @State private var visibility: String
    let parentID: UUID?
    let editingPost: DiaryPost?

    init(parentID: UUID? = nil, editingPost: DiaryPost? = nil) {
        self.parentID = parentID
        self.editingPost = editingPost
        _text = State(initialValue: editingPost?.text ?? "")
        _photos = State(initialValue: editingPost?.photos ?? [])
        _author = State(initialValue: editingPost.map { PostAuthorStore.selection(for: $0.id) } ?? .me)
        _location = State(initialValue: editingPost?.location ?? "")
        _publishDate = State(initialValue: editingPost?.createdAt ?? .now)
        _visibility = State(initialValue: editingPost?.visibility ?? "所有人可见")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    authorMenu
                    TextEditor(text: $text)
                        .font(.body)
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty { Text("现在在想什么？").foregroundStyle(.secondary).padding(.top, 8).allowsHitTesting(false) }
                        }
                    if !photos.isEmpty {
                        EditablePhotoGrid(data: $photos)
                    }
                    HStack {
                        if photos.count < 9 {
                            PhotosPicker(selection: $selection, maxSelectionCount: 9 - photos.count, matching: .images) {
                                Label("添加照片", systemImage: "photo.badge.plus")
                            }
                        }
                        if !photos.isEmpty {
                            Button("重新选择") { photos.removeAll(); selection.removeAll() }
                        }
                        Spacer()
                        Text("\(photos.count)/9").foregroundStyle(.secondary).font(.caption)
                        Text("\(text.count)").foregroundStyle(.secondary).font(.caption)
                    }
                    Divider()
                    LabelledTextField(title: "地点", systemImage: "mappin.and.ellipse", text: $location)
                    DatePicker("发布时间", selection: $publishDate)
                    Picker("谁可以看", selection: $visibility) {
                        Text("所有人可见").tag("所有人可见")
                        Text("仅自己可见").tag("仅自己可见")
                        Text("联系人可见").tag("联系人可见")
                    }
                }
                .padding()
            }
            .navigationTitle(editingPost != nil ? "编辑记录" : parentID == nil ? "新记录" : "回复自己")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let editingPost {
                            editingPost.text = cleanText
                            editingPost.photos = photos
                            editingPost.location = location.nilIfBlank
                            editingPost.createdAt = publishDate
                            editingPost.visibility = visibility
                            PostAuthorStore.set(author, for: editingPost.id)
                        } else {
                            let post = DiaryPost(
                                text: cleanText,
                                photos: photos,
                                parentID: parentID,
                                createdAt: publishDate,
                                location: location.nilIfBlank,
                                visibility: visibility
                            )
                            context.insert(post)
                            PostAuthorStore.set(author, for: post.id)
                        }
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photos.isEmpty)
                }
            }
            .onChange(of: selection) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    let additions = await items.asyncCompactMap { try? await $0.loadTransferable(type: Data.self) }
                    photos = Array((photos + additions).prefix(9))
                    selection.removeAll()
                }
            }
        }
    }

    private var authorMenu: some View {
        Menu {
            Button {
                author = .me
            } label: {
                Label(profile.displayName, systemImage: author == .me ? "checkmark" : "person.crop.circle")
            }
            ForEach(contacts) { contact in
                Button {
                    author = .contact(contact.id)
                } label: {
                    Label(contact.name, systemImage: author == .contact(contact.id) ? "checkmark" : "person.crop.circle")
                }
            }
        } label: {
            HStack(spacing: 10) {
                authorAvatar(size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text("发送人").font(.caption).foregroundStyle(.secondary)
                    Text(authorName).font(.subheadline.weight(.semibold))
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .softCard()
        }
        .buttonStyle(.plain)
    }

    private var authorName: String {
        switch author {
        case .me:
            profile.displayName
        case let .contact(id):
            contacts.first(where: { $0.id == id })?.name ?? profile.displayName
        }
    }

    @ViewBuilder private func authorAvatar(size: CGFloat) -> some View {
        switch author {
        case .me:
            AvatarView(data: profile.avatarData, size: size)
        case let .contact(id):
            if let contact = contacts.first(where: { $0.id == id }) {
                ContactAvatar(filename: contact.avatarFilename, size: size)
            } else {
                AvatarView(data: profile.avatarData, size: size)
            }
        }
    }
}

private struct EditablePhotoGrid: View {
    @Binding var data: [Data]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                ZStack(alignment: .topTrailing) {
                    if let image = UIImage(data: item) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(height: 105).frame(maxWidth: .infinity).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button { data.remove(at: index) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3).symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.65))
                            .padding(5)
                    }
                    .accessibilityLabel("删除第\(index + 1)张照片")
                }
                .onDrag { NSItemProvider(object: String(index) as NSString) }
                .onDrop(of: [.text], delegate: PhotoReorderDelegate(destination: index, data: $data))
            }
        }
    }
}

private struct PhotoReorderDelegate: DropDelegate {
    let destination: Int
    @Binding var data: [Data]

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { value, _ in
            guard let value = value as? NSString, let source = Int(value as String), source != destination else { return }
            Task { @MainActor in
                guard data.indices.contains(source), data.indices.contains(destination) else { return }
                let item = data.remove(at: source)
                data.insert(item, at: source < destination ? destination - 1 : destination)
            }
        }
        return true
    }
}

private struct LabelledTextField: View {
    let title: String
    let systemImage: String
    @Binding var text: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            TextField(title, text: $text).multilineTextAlignment(.trailing)
        }
    }
}

private extension Array where Element == PhotosPickerItem {
    func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
        var values: [T] = []
        for item in self { if let value = await transform(item) { values.append(value) } }
        return values
    }
}
