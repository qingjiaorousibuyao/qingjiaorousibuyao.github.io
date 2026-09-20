import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ContactChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var theme: ThemeSettings
    @Query(sort: \ChatMessage.createdAt) private var allMessages: [ChatMessage]
    let contact: Contact

    @State private var draft = ""
    @State private var sender: ChatSender = .me
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingImageData: Data?
    @State private var senderNotice: String?
    @State private var showsContactDetail = false
    @State private var showsBackgroundSettings = false
    @State private var chatBackgroundData: Data?
    @State private var voiceGestureActive = false
    @State private var voiceReachedMaximumDuration = false
    @State private var showsMicrophonePermissionAlert = false
    @State private var audioNotice: String?
    @StateObject private var audioManager = ChatAudioManager()
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
        .safeAreaInset(edge: .top, spacing: 0) {
            chatHeader
                .zIndex(20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composer
                .zIndex(20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
        .onDisappear {
            audioManager.cancelRecording()
            audioManager.stopPlayback()
        }
        .onChange(of: audioManager.elapsed) { _, elapsed in
            if audioManager.isRecording && elapsed >= 59.9 {
                voiceReachedMaximumDuration = true
                voiceGestureActive = false
                finishVoiceRecording()
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    pendingImageData = data
                }
                selectedPhoto = nil
            }
        }
        .alert("无法使用麦克风", isPresented: $showsMicrophonePermissionAlert) {
            Button("取消", role: .cancel) { }
            Button("前往设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
        } message: {
            Text("请在系统设置中允许 MyLog 使用麦克风，然后再录制语音消息。")
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
            .liquidGlass(cornerRadius: 22, isInteractive: true)

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
                    .liquidGlass(cornerRadius: 22, isInteractive: true)
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
                            showsAvatar: nextSender != message.senderValue,
                            audioManager: audioManager
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                Color.black.opacity(0.035)
            } else {
                LinearGradient(
                    colors: [theme.backgroundColors.first ?? .clear, theme.accent.opacity(0.10), theme.backgroundColors.last ?? .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if audioManager.isRecording {
                Text("● 正在录音 \(recordingTimeText)　松开发送")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
            } else if let audioNotice {
                Text(audioNotice)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if let pendingImageData, let image = UIImage(data: pendingImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            self.pendingImageData = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.65))
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                        .accessibilityLabel("移除待发送图片")
                    }
            }

            HStack(alignment: .bottom, spacing: 9) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "plus")
                        .font(.body.bold())
                        .frame(width: 42, height: 42)
                        .contentShape(Circle())
                        .liquidGlass(cornerRadius: 21, isInteractive: true)
                }
                .accessibilityLabel("选择图片")

                TextField("输入消息", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .liquidGlass(cornerRadius: 22, isInteractive: true)
                    .onSubmit(sendPendingContent)

                Button {
                    if hasPendingContent { sendPendingContent() }
                } label: {
                    Image(systemName: hasPendingContent ? "arrow.up" : audioManager.isRecording ? "waveform.circle.fill" : "waveform")
                        .font(.body.bold())
                        .foregroundStyle(hasPendingContent ? Color.white : audioManager.isRecording ? Color.red : Color.secondary)
                        .frame(width: 42, height: 42)
                        .contentShape(Circle())
                }
                .buttonStyle(LiquidGlassButtonStyle(
                    tint: hasPendingContent ? theme.accent : theme.accent.opacity(0.18),
                    cornerRadius: 21
                ))
                .opacity(hasPendingContent || audioManager.isRecording ? 1 : 0.72)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !hasPendingContent else { return }
                            beginVoiceRecording()
                        }
                        .onEnded { _ in
                            guard !hasPendingContent else { return }
                            voiceGestureActive = false
                            if !voiceReachedMaximumDuration {
                                finishVoiceRecording()
                            }
                            voiceReachedMaximumDuration = false
                        }
                )
                .accessibilityLabel(hasPendingContent ? "发送" : "按住录音")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var hasPendingContent: Bool {
        draft.nilIfBlank != nil || pendingImageData != nil
    }

    private var recordingTimeText: String {
        let seconds = max(0, Int(audioManager.elapsed))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func sendPendingContent() {
        let text = draft.nilIfBlank
        let imageData = pendingImageData
        guard text != nil || imageData != nil else { return }

        if let text {
            context.insert(ChatMessage(contactID: contact.id, sender: sender, type: .text, text: text))
        }
        if let imageData {
            sendImage(imageData, savesContext: false)
        }
        try? context.save()
        draft = ""
        pendingImageData = nil
        inputFocused = true
    }

    private func sendImage(_ data: Data, savesContext: Bool = true) {
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
        if savesContext { try? context.save() }
    }

    private func beginVoiceRecording() {
        guard !voiceGestureActive, !voiceReachedMaximumDuration, !audioManager.isRecording else { return }
        voiceGestureActive = true
        inputFocused = false
        Task {
            switch await audioManager.startRecording() {
            case .started:
                if !voiceGestureActive {
                    audioManager.cancelRecording()
                }
            case .permissionDenied:
                voiceGestureActive = false
                showsMicrophonePermissionAlert = true
            case .failed:
                voiceGestureActive = false
                showAudioNotice("无法开始录音")
            }
        }
    }

    private func finishVoiceRecording() {
        switch audioManager.finishRecording() {
        case let .recording(filename, duration):
            context.insert(ChatMessage(
                contactID: contact.id,
                sender: sender,
                type: .audio,
                audioPath: filename,
                audioDuration: duration
            ))
            try? context.save()
        case .tooShort:
            showAudioNotice("录音时间太短")
        case .none:
            break
        }
    }

    private func showAudioNotice(_ message: String) {
        audioNotice = message
        Task {
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            if audioNotice == message { audioNotice = nil }
        }
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
    @ObservedObject var audioManager: ChatAudioManager

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
                    .aspectRatio(
                        image.size.width > 0 && image.size.height > 0
                            ? image.size.width / image.size.height
                            : 1,
                        contentMode: .fit
                    )
                    .frame(maxWidth: 240)
                    .fixedSize(horizontal: false, vertical: true)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Label("图片不可用", systemImage: "photo.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .audio:
            VoiceMessageBubble(
                duration: message.audioDuration ?? 0,
                isPlaying: audioManager.playingMessageID == message.id
            ) {
                audioManager.togglePlayback(messageID: message.id, filename: message.audioPath)
            }
        }
    }
}
