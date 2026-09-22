import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let contact: Contact?
    @State private var nickname: String
    @State private var signature: String
    @State private var group: ContactGroup
    @State private var region: String
    @State private var avatarData: Data?
    @State private var profileBackgroundData: Data?
    @State private var chatBackgroundData: Data?
    @State private var avatarPicker: PhotosPickerItem?
    @State private var profileBackgroundPicker: PhotosPickerItem?
    @State private var chatBackgroundPicker: PhotosPickerItem?
    @State private var changedAvatar = false
    @State private var changedProfileBackground = false
    @State private var changedChatBackground = false
    @State private var showDiscardAlert = false
    @State private var saving = false

    init(contact: Contact? = nil) {
        self.contact = contact
        _nickname = State(initialValue: contact?.nickname ?? "")
        _signature = State(initialValue: contact?.signature ?? "")
        _group = State(initialValue: contact?.group ?? .ungrouped)
        _region = State(initialValue: contact?.region ?? "")
        _avatarData = State(initialValue: MediaStore.imageData(path: contact?.avatarPath))
        _profileBackgroundData = State(initialValue: MediaStore.imageData(path: contact?.profileBackgroundPath))
        _chatBackgroundData = State(initialValue: MediaStore.imageData(path: contact?.chatBackgroundPath))
    }

    private var valid: Bool { nickname.nilIfBlank != nil }
    private var dirty: Bool { nickname != (contact?.nickname ?? "") || signature != (contact?.signature ?? "") || group != (contact?.group ?? .ungrouped) || region != (contact?.region ?? "") || changedAvatar || changedProfileBackground || changedChatBackground }

    var body: some View {
        ZStack {
            EunoiaTheme.pageGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    PhotosPicker(selection: $avatarPicker, matching: .images) {
                        VStack(spacing: 8) { AvatarPreview(data: avatarData); Text("设置头像").font(.headline).foregroundStyle(EunoiaTheme.accent) }
                    }
                    VStack(spacing: 0) {
                        FormTextRow(title: "昵称", placeholder: "请输入昵称", text: $nickname)
                        Divider(); FormTextRow(title: "签名", placeholder: "写下一句介绍自己的话", text: $signature, axis: .vertical)
                        Divider(); HStack { Text("分组").fontWeight(.semibold).frame(width: 76, alignment: .leading); Picker("分组", selection: $group) { ForEach(ContactGroup.allCases) { Text($0.title).tag($0) } }.frame(maxWidth: .infinity, alignment: .trailing) }.frame(minHeight: 62).padding(.horizontal, 16)
                        Divider(); FormTextRow(title: "地区", placeholder: "未设置", text: $region)
                    }.softCard()
                    Text("背景设置").font(.title3.bold()).frame(maxWidth: .infinity, alignment: .leading)
                    BackgroundPickerCard(title: "主页背景", subtitle: "显示在联系人资料页顶部", data: profileBackgroundData, selection: $profileBackgroundPicker)
                    BackgroundPickerCard(title: "聊天背景", subtitle: "显示在你们的聊天页面", data: chatBackgroundData, selection: $chatBackgroundPicker)
                    Button(action: save) { Text(contact == nil ? "创建联系人" : "保存联系人").font(.headline).frame(maxWidth: .infinity).frame(height: 54).foregroundStyle(.white).background(valid ? EunoiaTheme.accent : EunoiaTheme.accentSoft, in: Capsule()) }
                        .disabled(!valid || saving)
                }.padding(20).padding(.bottom, 18)
            }.scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(contact == nil ? "新建联系人" : "编辑联系人")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .hidesEunoiaTabBar()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button { if dirty { showDiscardAlert = true } else { dismiss() } } label: { Image(systemName: "chevron.left") } }
            ToolbarItem(placement: .topBarTrailing) { Button(contact == nil ? "创建" : "保存", action: save).disabled(!valid || saving) }
        }
        .alert("放弃本次编辑？", isPresented: $showDiscardAlert) { Button("继续编辑", role: .cancel) { }; Button("放弃", role: .destructive) { dismiss() } } message: { Text("已填写的联系人资料不会保存。") }
        .onChange(of: avatarPicker) { _, item in load(item, into: $avatarData, changed: $changedAvatar) }
        .onChange(of: profileBackgroundPicker) { _, item in load(item, into: $profileBackgroundData, changed: $changedProfileBackground) }
        .onChange(of: chatBackgroundPicker) { _, item in load(item, into: $chatBackgroundData, changed: $changedChatBackground) }
    }

    private func load(_ item: PhotosPickerItem?, into data: Binding<Data?>, changed: Binding<Bool>) {
        guard let item else { return }
        Task { if let value = try? await item.loadTransferable(type: Data.self) { data.wrappedValue = value; changed.wrappedValue = true } }
    }

    private func save() {
        guard let cleanName = nickname.nilIfBlank, !saving else { return }
        saving = true
        let model = contact ?? Contact(nickname: cleanName)
        let oldAvatar = model.avatarPath, oldProfile = model.profileBackgroundPath, oldChat = model.chatBackgroundPath
        model.nickname = cleanName; model.signature = signature.trimmingCharacters(in: .whitespacesAndNewlines); model.group = group; model.region = region.trimmingCharacters(in: .whitespacesAndNewlines)
        if changedAvatar, let avatarData { model.avatarPath = MediaStore.saveImage(avatarData, prefix: "contact-avatar", maxDimension: 900) }
        if changedProfileBackground, let profileBackgroundData { model.profileBackgroundPath = MediaStore.saveImage(profileBackgroundData, prefix: "contact-profile-background", maxDimension: 2600) }
        if changedChatBackground, let chatBackgroundData { model.chatBackgroundPath = MediaStore.saveImage(chatBackgroundData, prefix: "contact-chat-background", maxDimension: 2600) }
        if contact == nil { context.insert(model) }
        do {
            try context.save()
            if oldAvatar != model.avatarPath { MediaStore.remove(path: oldAvatar) }; if oldProfile != model.profileBackgroundPath { MediaStore.remove(path: oldProfile) }; if oldChat != model.chatBackgroundPath { MediaStore.remove(path: oldChat) }
            dismiss()
        } catch { saving = false }
    }
}

private struct FormTextRow: View {
    let title: String; let placeholder: String; @Binding var text: String; var axis: Axis = .horizontal
    var body: some View { HStack(alignment: axis == .vertical ? .top : .center) { Text(title).fontWeight(.semibold).frame(width: 76, alignment: .leading); TextField(placeholder, text: $text, axis: axis).lineLimit(axis == .vertical ? 2...4 : 1...1) }.frame(minHeight: axis == .vertical ? 76 : 62).padding(.horizontal, 16) }
}

private struct AvatarPreview: View {
    let data: Data?
    var body: some View { Group { if let data, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() } else { Circle().fill(EunoiaTheme.muted).overlay(Image(systemName: "person.fill").font(.system(size: 48)).foregroundStyle(.secondary)) } }.frame(width: 118, height: 118).clipShape(Circle()).overlay(alignment: .bottomTrailing) { Circle().fill(EunoiaTheme.accent).frame(width: 42, height: 42).overlay(Image(systemName: "camera.fill").foregroundStyle(.white)) } }
}

private struct BackgroundPickerCard: View {
    let title: String; let subtitle: String; let data: Data?; @Binding var selection: PhotosPickerItem?
    var body: some View { PhotosPicker(selection: $selection, matching: .images) { HStack { VStack(alignment: .leading, spacing: 6) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.secondary) }; Spacer(); Group { if let data, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() } else { RoundedRectangle(cornerRadius: 16).fill(EunoiaTheme.accentSoft).overlay(Image(systemName: "photo").foregroundStyle(EunoiaTheme.accent)) } }.frame(width: 150, height: 100).clipShape(RoundedRectangle(cornerRadius: 16)) }.padding(16).softCard() }.buttonStyle(.plain) }
}
