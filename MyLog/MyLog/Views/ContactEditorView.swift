import SwiftUI
import SwiftData
import PhotosUI

struct ContactEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let contact: Contact?

    @State private var name: String
    @State private var bio: String
    @State private var gender: String
    @State private var birthday: Date
    @State private var hasBirthday: Bool
    @State private var hometown: String
    @State private var persona: String
    @State private var taboos: String
    @State private var avatarData: Data?
    @State private var coverData: Data?
    @State private var avatarItem: PhotosPickerItem?
    @State private var coverItem: PhotosPickerItem?
    @State private var removeAvatar = false
    @State private var removeCover = false
    @State private var showsMore = false

    init(contact: Contact? = nil) {
        self.contact = contact
        _name = State(initialValue: contact?.name ?? "")
        _bio = State(initialValue: contact?.bio ?? "")
        _gender = State(initialValue: contact?.gender ?? "")
        _birthday = State(initialValue: contact?.birthday ?? .now)
        _hasBirthday = State(initialValue: contact?.birthday != nil)
        _hometown = State(initialValue: contact?.hometown ?? "")
        _persona = State(initialValue: contact?.persona ?? "")
        _taboos = State(initialValue: contact?.taboos ?? "")
        _avatarData = State(initialValue: PersistentSettingsStore.loadImage(filename: contact?.avatarFilename))
        _coverData = State(initialValue: PersistentSettingsStore.loadImage(filename: contact?.coverImageFilename))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .center, spacing: 18) {
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            editableAvatar
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("姓名（必填）", text: $name)
                                .font(.title3.bold())
                            TextField("一句话简介", text: $bio, axis: .vertical)
                                .lineLimit(2...4)
                        }
                    }
                    if avatarData != nil {
                        Button("移除头像", role: .destructive) {
                            avatarData = nil
                            removeAvatar = true
                        }
                    }
                }

                Section("封面") {
                    PhotosPicker(selection: $coverItem, matching: .images) {
                        coverPreview
                    }
                    if coverData != nil {
                        Button("移除封面", role: .destructive) {
                            coverData = nil
                            removeCover = true
                        }
                    }
                }

                Section {
                    DisclosureGroup("更多资料", isExpanded: $showsMore) {
                        Picker("性别", selection: $gender) {
                            Text("未设置").tag("")
                            Text("女").tag("女")
                            Text("男").tag("男")
                            Text("其他").tag("其他")
                        }
                        Toggle("设置生日", isOn: $hasBirthday)
                        if hasBirthday {
                            DatePicker("生日", selection: $birthday, in: ...Date.now, displayedComponents: .date)
                        }
                        TextField("籍贯", text: $hometown)
                        TextField("人物设定", text: $persona, axis: .vertical)
                            .lineLimit(3...6)
                        TextField("禁忌", text: $taboos, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle(contact == nil ? "新建联系人" : "编辑联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(name.nilIfBlank == nil)
                }
            }
            .onChange(of: avatarItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        avatarData = data
                        removeAvatar = false
                    }
                }
            }
            .onChange(of: coverItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        coverData = data
                        removeCover = false
                    }
                }
            }
        }
    }

    private var editableAvatar: some View {
        Group {
            if let avatarData, let image = UIImage(data: avatarData) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Circle().fill(MyLogTheme.palePurple)
                    .overlay(Image(systemName: "camera.fill").foregroundStyle(MyLogTheme.purple))
            }
        }
        .frame(width: 86, height: 86)
        .clipShape(Circle())
    }

    private var coverPreview: some View {
        Group {
            if let coverData, let image = UIImage(data: coverData) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 14).fill(MyLogTheme.palePurple.opacity(0.7))
                    .overlay(Label("选择封面图片", systemImage: "photo").foregroundStyle(.secondary))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func save() {
        guard let cleanName = name.nilIfBlank else { return }
        let target = contact ?? Contact(name: cleanName)
        let identifier = target.id.uuidString.lowercased()

        if removeAvatar {
            PersistentSettingsStore.removeImage(filename: target.avatarFilename)
            target.avatarFilename = nil
        } else if avatarItem != nil, let avatarData {
            let oldFilename = target.avatarFilename
            if let newFilename = PersistentSettingsStore.saveImage(
                avatarData,
                filename: "contact-\(identifier)-avatar.jpg",
                maxDimension: 800
            ) {
                target.avatarFilename = newFilename
                if oldFilename != newFilename { PersistentSettingsStore.removeImage(filename: oldFilename) }
            }
        }

        if removeCover {
            PersistentSettingsStore.removeImage(filename: target.coverImageFilename)
            target.coverImageFilename = nil
        } else if coverItem != nil, let coverData {
            let oldFilename = target.coverImageFilename
            if let newFilename = PersistentSettingsStore.saveImage(
                coverData,
                filename: "contact-\(identifier)-cover.jpg",
                maxDimension: 2400
            ) {
                target.coverImageFilename = newFilename
                if oldFilename != newFilename { PersistentSettingsStore.removeImage(filename: oldFilename) }
            }
        }

        target.name = cleanName
        target.bio = bio.nilIfBlank
        target.gender = gender.nilIfBlank
        target.birthday = hasBirthday ? birthday : nil
        target.hometown = hometown.nilIfBlank
        target.persona = persona.nilIfBlank
        target.taboos = taboos.nilIfBlank
        if contact == nil { context.insert(target) }
        try? context.save()
        dismiss()
    }
}
