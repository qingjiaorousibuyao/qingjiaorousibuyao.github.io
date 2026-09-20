import SwiftUI
import SwiftData
import PhotosUI

struct ContactChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var theme: ThemeSettings
    @Query(sort: \ChatMessage.createdAt) private var allMessages: [ChatMessage]
    let contact: Contact

    @State private var draft = ""
    @State private var sender: ChatSender = .me
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var senderNotice: String?
    @State private var showsContactDetail = false
    @State private var showsBackgroundSettings = false
    @State private var chatBackgroundData: Data?
    @FocusState private var inputFocused: Bool

    private var messages: [ChatMessage] {
        allMessages.filter { $0.contactID == contact.id }
    }

    init(contact: Contact) {
        self.contact = contact
        _chatBackgroundData = State(initialValue: ContactChatBackgroundStore.data(for: contact.id))
    }

    var body: some View {
        ZStack {
            chatBackground
            messageList
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { chatHeader }
        .safeAreaInset(edge: .bottom) { composer }
        .overlay(alignment: .top) {
            if let senderNotice {
                Text(senderNotice)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .liquidGlass(cornerRadius: 20, tint: theme.accent, tintStrength: 0.08)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showsContactDetail) {
            ContactDetailView(contact: contact)
        }
        .sheet(isPresented: $showsBackgroundSettings, onDismiss: {
            chatBackgroundData = ContactChatBackgroundStore.data(for: contact.id)
        }) {
            ContactEditorView(contact: contact)
        }
        .onAppear {
            chatBackgroundData = ContactChatBackgroundStore.data(for: contact.id)
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    sendImage(data)
                }
                selectedPhoto = nil
            }
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 22))
            .accessibilityLabel("返回")

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                ContactAvatar(filename: contact.avatarFilename, size: 32)
                    .contentShape(Circle())
                    .gesture(avatarGesture)
                Text(contact.name)
                    .font(.headline)
                    .lineLimit(1)
            }
            .padding(.leading, 7)
            .padding(.trailing, 13)
            .frame(height: 44)
            .liquidGlass(cornerRadius: 22)

            Spacer(minLength: 0)

            Menu {
                Button("联系人资料", systemImage: "person.text.rectangle") {
                    showsContactDetail = true
                }
                Button("聊天背景", systemImage: "photo.on.rectangle") {
                    showsBackgroundSettings = true
                }
                Button("取消", role: .cancel) { }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.bold())
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .liquidGlass(cornerRadius: 22)
            }
            .accessibilityLabel("更多")
            .zIndex(20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .zIndex(20)
    }

    private var avatarGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.55, maximumDistance: 12)
            .exclusively(before: TapGesture(count: 2))
            .onEnded { result in
                switch result {
                case .first(_):
                    showsContactDetail = true
                case .second(_):
                    toggleSender()
                }
            }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        let previousSender = index > 0 ? messages[index - 1].senderValue : nil
                        let nextSender = index + 1 < messages.count ? messages[index + 1].senderValue : nil
                        MessageBubbleRow(
                            message: message,
                            contactAvatarFilename: contact.avatarFilename,
                            showsAvatar: nextSender != message.senderValue
                        )
                        .padding(.top, previousSender == message.senderValue ? 3 : 14)
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                Task {
                    await Task.yield()
                    scrollToBottom(proxy, animated: false)
                }
            }
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy, animated: true) }
        }
    }

    private var chatBackground: some View {
        ZStack {
            if let chatBackgroundData, let image = UIImage(data: chatBackgroundData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                Color.black.opacity(0.035)
            } else {
                LinearGradient(
                    colors: [theme.backgroundColors.first ?? .clear, theme.accent.opacity(0.10), theme.backgroundColors.last ?? .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 9) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "plus")
                    .font(.body.bold())
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
                    .liquidGlass(cornerRadius: 21)
            }
            .accessibilityLabel("选择图片")

            TextField("输入消息", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .liquidGlass(cornerRadius: 22)
                .onSubmit(sendText)

            Button(action: sendText) {
                Image(systemName: draft.nilIfBlank == nil ? "waveform" : "arrow.up")
                    .font(.body.bold())
                    .foregroundStyle(draft.nilIfBlank == nil ? Color.secondary : Color.white)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(LiquidGlassButtonStyle(
                tint: draft.nilIfBlank == nil ? theme.accent.opacity(0.18) : theme.accent,
                cornerRadius: 21
            ))
            .disabled(draft.nilIfBlank == nil)
            .opacity(draft.nilIfBlank == nil ? 0.45 : 1)
            .accessibilityLabel("发送")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func sendText() {
        guard let text = draft.nilIfBlank else { return }
        context.insert(ChatMessage(contactID: contact.id, sender: sender, type: .text, text: text))
        try? context.save()
        draft = ""
        inputFocused = true
    }

    private func sendImage(_ data: Data) {
        let messageID = UUID()
        guard let path = PersistentSettingsStore.saveImage(
            data,
            filename: "chat-\(contact.id.uuidString.lowercased())-\(messageID.uuidString.lowercased()).jpg",
            maxDimension: 2200
        ) else { return }
        context.insert(ChatMessage(
            id: messageID,
            contactID: contact.id,
            sender: sender,
            type: .image,
            imagePath: path
        ))
        try? context.save()
    }

    private func toggleSender() {
        sender = sender == .me ? .contact : .me
        withAnimation(.easeOut(duration: 0.2)) {
            senderNotice = "当前发送人：\(sender == .me ? "我" : contact.name)"
        }
        let notice = senderNotice
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if senderNotice == notice {
                withAnimation(.easeIn(duration: 0.2)) { senderNotice = nil }
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let id = messages.last?.id else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(id, anchor: .bottom) }
        } else {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }
}

private struct MessageBubbleRow: View {
    @EnvironmentObject private var theme: ThemeSettings
    @EnvironmentObject private var profile: ProfileSettings
    let message: ChatMessage
    let contactAvatarFilename: String?
    let showsAvatar: Bool

    private var isMe: Bool { message.senderValue == .me }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 54) }

            if !isMe {
                if showsAvatar {
                    ContactAvatar(filename: contactAvatarFilename, size: 30)
                } else {
                    Color.clear.frame(width: 30, height: 1)
                }
            }

            messageContent
                .padding(message.typeValue == .text ? 11 : 4)
                .liquidGlass(
                    cornerRadius: 17,
                    tint: isMe ? theme.accent : .clear,
                    tintStrength: isMe ? 0.18 : 0.055
                )

            if isMe {
                if showsAvatar {
                    AvatarView(data: profile.avatarData, size: 30)
                } else {
                    Color.clear.frame(width: 30, height: 1)
                }
            }

            if !isMe { Spacer(minLength: 54) }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var messageContent: some View {
        switch message.typeValue {
        case .text:
            Text(message.text ?? "")
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        case .image:
            if let data = PersistentSettingsStore.loadImage(filename: message.imagePath),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 230, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Label("图片不可用", systemImage: "photo.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
