import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ContactChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \ChatMessage.createdAt) private var allMessages: [ChatMessage]
    @AppStorage("profile.nickname") private var profileName = "Eunoia用户"
    let contact: Contact
    @State private var draft = ""
    @State private var sender: ChatSender = .currentUser
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingImageData: Data?
    @State private var messageToDelete: ChatMessage?
    @State private var microphoneAlert = false
    @State private var voiceGestureActive = false
    @State private var notice: String?
    @StateObject private var audioManager = ChatAudioManager()
    @FocusState private var inputFocused: Bool

    private var messages: [ChatMessage] { allMessages.filter { $0.contactID == contact.id } }
    private var hasPendingContent: Bool { draft.nilIfBlank != nil || pendingImageData != nil }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        let previous = index > 0 ? messages[index - 1] : nil
                        let gap = previous.map { message.createdAt.timeIntervalSince($0.createdAt) } ?? .infinity
                        let showTime = previous == nil || gap >= ChatMessageTimeFormatter.groupInterval
                        let grouped = previous?.senderValue == message.senderValue && gap < 120
                        VStack(spacing: 7) {
                            if showTime { Text(ChatMessageTimeFormatter.separatorText(from: message.createdAt)).font(.caption2).foregroundStyle(.secondary).padding(.vertical, 5) }
                            MessageBubbleRow(message: message, contact: contact, profileName: profileName, grouped: grouped, audioManager: audioManager)
                                .contextMenu { Button("删除", systemImage: "trash", role: .destructive) { messageToDelete = message } }
                        }.padding(.top, showTime ? 12 : grouped ? 3 : 8).id(message.id)
                    }
                    Color.clear.frame(height: 1).id("chat-bottom")
                }.padding(.horizontal, 12).padding(.vertical, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(chatBackground)
            .safeAreaInset(edge: .top, spacing: 0) { chatHeader }
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
            .toolbar(.hidden, for: .navigationBar).hidesEunoiaTabBar()
            .onAppear { Task { await scrollAfterLayout(proxy, animated: false) } }
            .onChange(of: messages.count) { _, _ in Task { await scrollAfterLayout(proxy, animated: true) } }
        }
        .overlay(alignment: .top) { if let notice { Text(notice).font(.subheadline.weight(.medium)).padding(.horizontal, 14).padding(.vertical, 9).background(.ultraThinMaterial, in: Capsule()).padding(.top, 62) } }
        .onChange(of: selectedPhoto) { _, item in guard let item else { return }; Task { pendingImageData = try? await item.loadTransferable(type: Data.self); selectedPhoto = nil } }
        .onDisappear { audioManager.cancelRecording(); audioManager.stopPlayback() }
        .alert("无法使用麦克风", isPresented: $microphoneAlert) { Button("好", role: .cancel) { } } message: { Text("请在系统设置中允许 Eunoia 使用麦克风。") }
        .confirmationDialog("删除这条消息？", isPresented: Binding(get: { messageToDelete != nil }, set: { if !$0 { messageToDelete = nil } }), titleVisibility: .visible) { Button("删除", role: .destructive) { if let messageToDelete { delete(messageToDelete) }; messageToDelete = nil }; Button("取消", role: .cancel) { messageToDelete = nil } }
    }

    private var chatHeader: some View {
        HStack { Button { dismiss() } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }; Spacer(); HStack(spacing: 8) { ContactAvatar(path: contact.avatarPath, size: 36); Text(contact.nickname).font(.headline).lineLimit(1) }.padding(.horizontal, 12).frame(height: 44).background(.ultraThinMaterial, in: Capsule()); Spacer(); Menu { Menu("发送身份", systemImage: "person.2") { Button(profileName, systemImage: sender == .currentUser ? "checkmark" : "person") { selectSender(.currentUser) }; Button(contact.nickname, systemImage: sender == .contact ? "checkmark" : "person.crop.circle") { selectSender(.contact) } } } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) } }.padding(.horizontal, 10).padding(.vertical, 6).background(.ultraThinMaterial)
    }

    private var chatBackground: some View {
        Group { if let data = MediaStore.imageData(path: contact.chatBackgroundPath), let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill().overlay(EunoiaTheme.background.opacity(0.35)) } else { EunoiaTheme.pageGradient } }.ignoresSafeArea().allowsHitTesting(false)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let pendingImageData, let image = UIImage(data: pendingImageData) { Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(alignment: .topTrailing) { Button { self.pendingImageData = nil } label: { Image(systemName: "xmark.circle.fill").symbolRenderingMode(.palette).foregroundStyle(.white, .black.opacity(0.65)) }.padding(4) } }
            if audioManager.isRecording { Text("录音中 \(Int(audioManager.elapsed)) 秒 · 松开发送").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
            HStack(alignment: .bottom, spacing: 9) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) { Image(systemName: "plus").font(.body.bold()).frame(width: 42, height: 42).background(EunoiaTheme.muted, in: Circle()) }
                TextField("输入消息", text: $draft, axis: .vertical).lineLimit(1...5).focused($inputFocused).padding(.horizontal, 14).padding(.vertical, 11).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                Button { if hasPendingContent { sendPendingContent() } } label: { Image(systemName: hasPendingContent ? "arrow.up" : audioManager.isRecording ? "waveform.circle.fill" : "waveform").font(.body.bold()).foregroundStyle(hasPendingContent ? Color.white : EunoiaTheme.accent).frame(width: 42, height: 42).background(hasPendingContent ? EunoiaTheme.accent : EunoiaTheme.accentSoft, in: Circle()) }
                    .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in if !hasPendingContent && !voiceGestureActive { beginRecording() } }.onEnded { _ in if !hasPendingContent && voiceGestureActive { voiceGestureActive = false; finishRecording() } })
            }
        }.padding(.horizontal, 12).padding(.vertical, 8).background(.ultraThinMaterial)
    }

    private func sendPendingContent() {
        let text = draft.nilIfBlank, image = pendingImageData
        guard text != nil || image != nil else { return }
        if let text { context.insert(ChatMessage(contactID: contact.id, sender: sender, type: .text, text: text)) }
        if let image, let path = MediaStore.saveImage(image, prefix: "chat-\(contact.id.uuidString.lowercased())", maxDimension: 2200) { context.insert(ChatMessage(contactID: contact.id, sender: sender, type: .image, imagePath: path)) }
        try? context.save(); draft = ""; pendingImageData = nil; inputFocused = true
    }

    private func beginRecording() {
        voiceGestureActive = true; inputFocused = false
        Task { switch await audioManager.startRecording() { case .started: break; case .permissionDenied: voiceGestureActive = false; microphoneAlert = true; case .failed: voiceGestureActive = false; showNotice("无法开始录音") } }
    }
    private func finishRecording() {
        switch audioManager.finishRecording() { case let .recording(filename, duration): context.insert(ChatMessage(contactID: contact.id, sender: sender, type: .audio, audioPath: filename, audioDuration: duration)); try? context.save(); case .tooShort: showNotice("录音时间太短"); case .none: break }
    }
    private func delete(_ message: ChatMessage) { if message.typeValue == .image { MediaStore.remove(path: message.imagePath) }; if message.typeValue == .audio { ChatAudioStore.remove(filename: message.audioPath) }; context.delete(message); try? context.save() }
    private func selectSender(_ value: ChatSender) { sender = value; showNotice("当前发送人：\(value == .currentUser ? profileName : contact.nickname)") }
    private func showNotice(_ value: String) { notice = value; Task { try? await Task.sleep(for: .seconds(1.3)); if notice == value { notice = nil } } }
    @MainActor private func scrollAfterLayout(_ proxy: ScrollViewProxy, animated: Bool) async { await Task.yield(); if animated { withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("chat-bottom", anchor: .bottom) } } else { proxy.scrollTo("chat-bottom", anchor: .bottom) } }
}

private struct MessageBubbleRow: View {
    let message: ChatMessage; let contact: Contact; let profileName: String; let grouped: Bool
    @ObservedObject var audioManager: ChatAudioManager
    private var mine: Bool { message.senderValue == .currentUser }
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if mine { Spacer(minLength: 54) }
            if !mine { senderAvatar }
            content.padding(message.typeValue == .text ? 11 : 4).background(mine ? EunoiaTheme.accentSoft : Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 22))
            if mine { senderAvatar }
            if !mine { Spacer(minLength: 54) }
        }
    }
    private var senderAvatar: some View { VStack(spacing: 3) { if grouped { Color.clear.frame(width: 40, height: 14) } else if mine { Circle().fill(EunoiaTheme.muted).frame(width: 40, height: 40).overlay(Image(systemName: "person.fill").foregroundStyle(EunoiaTheme.accent)) } else { ContactAvatar(path: contact.avatarPath, size: 40) }; if !grouped { Text(ChatMessageTimeFormatter.messageTime(from: message.createdAt)).font(.system(size: 8)).foregroundStyle(.tertiary) } } }
    @ViewBuilder private var content: some View {
        switch message.typeValue {
        case .text: Text(message.text ?? "").fixedSize(horizontal: false, vertical: true)
        case .image: if let data = MediaStore.imageData(path: message.imagePath), let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: 240).clipShape(RoundedRectangle(cornerRadius: 14)) } else { Label("图片不可用", systemImage: "photo.badge.exclamationmark").font(.caption) }
        case .audio: VoiceMessageBubble(duration: message.audioDuration ?? 0, isPlaying: audioManager.playingMessageID == message.id) { audioManager.togglePlayback(messageID: message.id, filename: message.audioPath) }
        }
    }
}
