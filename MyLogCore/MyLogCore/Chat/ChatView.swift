import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ChatView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var profile: LocalProfileStore
    @Query(sort: \ChatMessage.createdAt) private var allMessages: [ChatMessage]
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    @State private var activeContactID: UUID
    @State private var sender: MessageSender = .me
    @State private var draft = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingImage: Data?
    @State private var editingContact = false
    @State private var deletingMessage: ChatMessage?
    @State private var recordingGesture = false
    @State private var notice: String?
    @StateObject private var audio = ChatAudioController()
    @FocusState private var focused: Bool

    init(initialContact: Contact) { _activeContactID = State(initialValue: initialContact.id) }

    private var contact: Contact? { contacts.first { $0.id == activeContactID } }
    private var messages: [ChatMessage] { allMessages.filter { $0.contactID == activeContactID } }

    var body: some View {
        ZStack {
            background
            messageList
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    ContactAvatar(path: contact?.avatarPath, size: 36)
                    Text(contact?.name ?? "联系人").font(.headline)
                }
                .padding(.horizontal, 12).frame(height: 44).liquidGlass(radius: 22)
            }
            ToolbarItem(placement: .topBarTrailing) { contactMenu }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $editingContact) { if let contact { ContactEditorView(contact: contact) } }
        .onChange(of: selectedPhoto) { _, item in Task { pendingImage = try? await item?.loadTransferable(type: Data.self); selectedPhoto = nil } }
        .onChange(of: audio.elapsed) { _, elapsed in if audio.isRecording && elapsed >= 59.9 { endRecording() } }
        .onDisappear { audio.cancel(); audio.stopPlayback() }
        .alert("录音提示", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("好", role: .cancel) { notice = nil }
        } message: { Text(notice ?? "") }
        .confirmationDialog("删除这条消息？", isPresented: Binding(get: { deletingMessage != nil }, set: { if !$0 { deletingMessage = nil } })) {
            Button("删除", role: .destructive) { if let deletingMessage { delete(deletingMessage) }; self.deletingMessage = nil }
            Button("取消", role: .cancel) { deletingMessage = nil }
        }
    }

    private var background: some View {
        Group {
            if let image = MediaStore.image(path: contact?.chatBackgroundPath) { Image(uiImage: image).resizable().scaledToFill() }
            else { PaperBackground() }
        }
        .ignoresSafeArea().allowsHitTesting(false)
    }

    private var contactMenu: some View {
        Menu {
            Menu("切换联系人", systemImage: "person.2") {
                ForEach(contacts) { candidate in
                    Button { activeContactID = candidate.id } label: { Label(candidate.name, systemImage: candidate.id == activeContactID ? "checkmark" : "person.crop.circle") }
                }
            }
            Menu("发送身份", systemImage: "arrow.left.arrow.right") {
                Button(profile.name) { sender = .me }
                if let contact { Button(contact.name) { sender = .contact } }
            }
            Button("编辑联系人", systemImage: "pencil") { editingContact = true }
        } label: {
            Image(systemName: "ellipsis").font(.headline.bold()).frame(width: 44, height: 44).contentShape(Circle()).liquidGlass(radius: 22, interactive: true)
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        if index == 0 || message.createdAt.timeIntervalSince(messages[index - 1].createdAt) >= ChatTimeFormatter.separatorInterval {
                            Text(ChatTimeFormatter.separator(message.createdAt)).font(.caption2).foregroundStyle(.secondary)
                                .padding(.horizontal, 10).padding(.vertical, 5).liquidGlass(radius: 12, strength: 0.04).padding(.vertical, 8)
                        }
                        MessageRow(message: message, contact: contact, audio: audio)
                            .contextMenu { Button("删除", systemImage: "trash", role: .destructive) { deletingMessage = message } }
                            .id(message.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .task(id: activeContactID) { await Task.yield(); proxy.scrollTo("bottom", anchor: .bottom) }
            .onChange(of: messages.count) { _, _ in withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) } }
        }
    }

    private var composer: some View {
        VStack(spacing: 6) {
            if recordingGesture || audio.isRecording {
                HStack(spacing: 8) { Circle().fill(.red).frame(width: 7, height: 7); Text(time(audio.elapsed)).monospacedDigit(); Text("松开发送").foregroundStyle(.secondary) }
                    .font(.caption).padding(.horizontal, 14).padding(.vertical, 9).liquidGlass(radius: 20, tint: AppPalette.accent, strength: 0.08)
            }
            if let pendingImage, let image = UIImage(data: pendingImage) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        Button { self.pendingImage = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.white, .black.opacity(0.65)) }
                    }
            }
            HStack(spacing: 9) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) { Image(systemName: "plus").frame(width: 42, height: 42).liquidGlass(radius: 21, interactive: true) }
                TextField("输入消息", text: $draft, axis: .vertical).lineLimit(1...5).focused($focused)
                    .padding(.horizontal, 14).padding(.vertical, 11).liquidGlass(radius: 22, interactive: true)
                Button { if hasContent { send() } } label: {
                    Image(systemName: hasContent ? "arrow.up" : "waveform").font(.body.bold()).foregroundStyle(AppPalette.accent).frame(width: 42, height: 42)
                }
                .buttonStyle(GlassButtonStyle(tint: AppPalette.accent.opacity(0.18), radius: 21))
                .scaleEffect(recordingGesture ? 0.94 : 1)
                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in beginRecording() }.onEnded { _ in endRecording() })
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var hasContent: Bool { draft.nonBlank != nil || pendingImage != nil }
    private func time(_ value: TimeInterval) -> String { String(format: "%02d:%02d", Int(value) / 60, Int(value) % 60) }

    private func send() {
        if let text = draft.nonBlank { context.insert(ChatMessage(contactID: activeContactID, sender: sender, kind: .text, text: text)) }
        if let pendingImage, let path = MediaStore.saveImage(pendingImage, category: "chat-image") {
            context.insert(ChatMessage(contactID: activeContactID, sender: sender, kind: .image, imagePath: path))
        }
        try? context.save(); draft = ""; pendingImage = nil
    }

    private func beginRecording() {
        guard !hasContent, !recordingGesture, !audio.isRecording else { return }
        recordingGesture = true; focused = false
        Task {
            switch await audio.start() {
            case .started: if !recordingGesture { audio.cancel() }
            case .denied: recordingGesture = false; notice = "请在系统设置中允许麦克风权限"
            case .failed: recordingGesture = false; notice = "无法开始录音"
            }
        }
    }

    private func endRecording() {
        guard recordingGesture else { return }
        recordingGesture = false
        switch audio.finish() {
        case let .saved(path, duration): context.insert(ChatMessage(contactID: activeContactID, sender: sender, kind: .audio, audioPath: path, audioDuration: duration)); try? context.save()
        case .tooShort: notice = "录音时间太短"
        case .none: break
        }
    }

    private func delete(_ message: ChatMessage) {
        MediaStore.remove(path: message.imagePath); MediaStore.remove(path: message.audioPath); context.delete(message); try? context.save()
    }
}

private struct MessageRow: View {
    @EnvironmentObject private var profile: LocalProfileStore
    let message: ChatMessage
    let contact: Contact?
    @ObservedObject var audio: ChatAudioController
    private var isMe: Bool { message.senderValue == .me }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isMe { Spacer(minLength: 54) }
            if !isMe { identity(isMe: false) }
            content.padding(message.kindValue == .text ? 11 : 4)
                .liquidGlass(radius: 24, tint: isMe ? AppPalette.accent : .clear, strength: isMe ? 0.18 : 0.055)
            if isMe { identity(isMe: true) }
            if !isMe { Spacer(minLength: 54) }
        }
    }

    private func identity(isMe: Bool) -> some View {
        VStack(spacing: 3) {
            if isMe { AvatarView(image: profile.avatar, size: 44) } else { ContactAvatar(path: contact?.avatarPath, size: 44) }
            Text(ChatTimeFormatter.message(message.createdAt)).font(.system(size: 8)).foregroundStyle(.tertiary).fixedSize()
        }
    }

    @ViewBuilder private var content: some View {
        switch message.kindValue {
        case .text: Text(message.text ?? "").fixedSize(horizontal: false, vertical: true)
        case .image:
            if let image = MediaStore.image(path: message.imagePath) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: 240).clipShape(RoundedRectangle(cornerRadius: 18))
            }
        case .audio:
            VoiceMessageBubble(duration: message.audioDuration ?? 0, isPlaying: audio.playingID == message.id) {
                audio.toggle(messageID: message.id, path: message.audioPath)
            }
        }
    }
}
