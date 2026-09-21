import PhotosUI
import SwiftData
import SwiftUI

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
    @State private var avatar: Data?
    @State private var cover: Data?
    @State private var background: Data?
    @State private var avatarItem: PhotosPickerItem?
    @State private var coverItem: PhotosPickerItem?
    @State private var backgroundItem: PhotosPickerItem?
    @State private var more = false
    @State private var removeAvatar = false
    @State private var removeCover = false
    @State private var removeBackground = false

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
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 18) {
                        PhotosPicker(selection: $avatarItem, matching: .images) { avatarPreview }
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("姓名（必填）", text: $name).font(.title3.bold())
                            TextField("一句话简介", text: $bio, axis: .vertical).lineLimit(2...4)
                        }
                    }
                    if avatar != nil || (!removeAvatar && contact?.avatarPath != nil) {
                        Button("移除头像", role: .destructive) { avatar = nil; removeAvatar = true }
                    }
                }
                imageSection("封面", data: cover, path: removeCover ? nil : contact?.coverPath, item: $coverItem, height: 130, remove: { cover = nil; removeCover = true })
                imageSection("聊天背景", data: background, path: removeBackground ? nil : contact?.chatBackgroundPath, item: $backgroundItem, height: 150, remove: { background = nil; removeBackground = true })
                Section {
                    DisclosureGroup("更多资料", isExpanded: $more) {
                        Picker("性别", selection: $gender) { Text("未设置").tag(""); Text("女").tag("女"); Text("男").tag("男"); Text("其他").tag("其他") }
                        Toggle("设置生日", isOn: $hasBirthday)
                        if hasBirthday { DatePicker("生日", selection: $birthday, in: ...Date.now, displayedComponents: .date) }
                        TextField("籍贯", text: $hometown)
                        TextField("人物设定", text: $persona, axis: .vertical).lineLimit(3...6)
                        TextField("禁忌", text: $taboos, axis: .vertical).lineLimit(3...6)
                    }
                }
            }
            .navigationTitle(contact == nil ? "新建联系人" : "编辑联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).disabled(name.nonBlank == nil) }
            }
            .onChange(of: avatarItem) { _, item in Task { avatar = try? await item?.loadTransferable(type: Data.self); removeAvatar = false } }
            .onChange(of: coverItem) { _, item in Task { cover = try? await item?.loadTransferable(type: Data.self); removeCover = false } }
            .onChange(of: backgroundItem) { _, item in Task { background = try? await item?.loadTransferable(type: Data.self); removeBackground = false } }
        }
    }

    private var avatarPreview: some View {
        Group {
            if let image = avatar.flatMap(UIImage.init(data:)) ?? MediaStore.image(path: removeAvatar ? nil : contact?.avatarPath) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Circle().fill(AppPalette.palePurple).overlay(Image(systemName: "camera.fill").foregroundStyle(AppPalette.accent))
            }
        }
        .frame(width: 86, height: 86).clipShape(Circle())
    }

    private func imageSection(_ title: String, data: Data?, path: String?, item: Binding<PhotosPickerItem?>, height: CGFloat, remove: @escaping () -> Void) -> some View {
        Section(title) {
            PhotosPicker(selection: item, matching: .images) {
                Group {
                    if let image = data.flatMap(UIImage.init(data:)) ?? MediaStore.image(path: path) { Image(uiImage: image).resizable().scaledToFill() }
                    else { RoundedRectangle(cornerRadius: 14).fill(AppPalette.palePurple.opacity(0.6)).overlay(Label("选择图片", systemImage: "photo")) }
                }
                .frame(maxWidth: .infinity).frame(height: height).clipped().clipShape(RoundedRectangle(cornerRadius: 14))
            }
            if data != nil || path != nil { Button("移除并恢复默认", role: .destructive, action: remove) }
        }
    }

    private func replace(_ old: String?, with data: Data?, category: String) -> String? {
        guard let data else { return old }
        MediaStore.remove(path: old)
        return MediaStore.saveImage(data, category: category)
    }

    private func save() {
        guard let cleanName = name.nonBlank else { return }
        let target = contact ?? Contact(name: cleanName)
        target.name = cleanName; target.bio = bio.nonBlank; target.gender = gender.nonBlank
        target.birthday = hasBirthday ? birthday : nil; target.hometown = hometown.nonBlank
        target.persona = persona.nonBlank; target.taboos = taboos.nonBlank
        if removeAvatar { MediaStore.remove(path: target.avatarPath); target.avatarPath = nil }
        else { target.avatarPath = replace(target.avatarPath, with: avatar, category: "contact-avatar") }
        if removeCover { MediaStore.remove(path: target.coverPath); target.coverPath = nil }
        else { target.coverPath = replace(target.coverPath, with: cover, category: "contact-cover") }
        if removeBackground { MediaStore.remove(path: target.chatBackgroundPath); target.chatBackgroundPath = nil }
        else { target.chatBackgroundPath = replace(target.chatBackgroundPath, with: background, category: "chat-background") }
        if contact == nil { context.insert(target) }
        try? context.save(); dismiss()
    }
}
