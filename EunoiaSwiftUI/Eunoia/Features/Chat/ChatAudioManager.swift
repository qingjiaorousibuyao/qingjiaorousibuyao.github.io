import AVFoundation
import Combine
import Foundation

enum ChatAudioStartResult { case started, permissionDenied, failed }
enum ChatAudioFinishResult { case recording(filename: String, duration: TimeInterval), tooShort, none }

final class ChatAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var playingMessageID: UUID?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var recordingURL: URL?

    func startRecording() async -> ChatAudioStartResult {
        guard !isRecording else { return .started }
        let granted: Bool
        switch AVAudioApplication.shared.recordPermission {
        case .granted: granted = true
        case .denied: granted = false
        case .undetermined: granted = await withCheckedContinuation { continuation in AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) } }
        @unknown default: granted = false
        }
        guard granted else { return .permissionDenied }
        stopPlayback()
        do {
            let session = AVAudioSession.sharedInstance(); try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth]); try session.setActive(true)
            let url = ChatAudioStore.makeRecordingURL()
            let settings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44_100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            guard recorder.prepareToRecord(), recorder.record() else { ChatAudioStore.remove(filename: url.lastPathComponent); return .failed }
            self.recorder = recorder; recordingURL = url; elapsed = 0; isRecording = true
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in guard let self, let recorder = self.recorder else { return }; self.elapsed = min(recorder.currentTime, 60) }
            return .started
        } catch { return .failed }
    }

    func finishRecording() -> ChatAudioFinishResult {
        guard let recorder, let recordingURL else { return .none }
        let duration = recorder.currentTime; recorder.stop(); finishSession()
        guard duration >= 0.5 else { ChatAudioStore.remove(filename: recordingURL.lastPathComponent); return .tooShort }
        return .recording(filename: recordingURL.lastPathComponent, duration: min(duration, 60))
    }
    func cancelRecording() { recorder?.stop(); if let recordingURL { ChatAudioStore.remove(filename: recordingURL.lastPathComponent) }; finishSession() }
    func togglePlayback(messageID: UUID, filename: String?) {
        if playingMessageID == messageID { stopPlayback(); return }
        guard let url = ChatAudioStore.url(for: filename) else { return }
        do { stopPlayback(); let session = AVAudioSession.sharedInstance(); try session.setCategory(.playback, mode: .spokenAudio); try session.setActive(true); let player = try AVAudioPlayer(contentsOf: url); player.delegate = self; guard player.play() else { return }; self.player = player; playingMessageID = messageID } catch { stopPlayback() }
    }
    func stopPlayback() { player?.stop(); player = nil; playingMessageID = nil; try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { stopPlayback() }
    private func finishSession() { timer?.invalidate(); timer = nil; recorder = nil; recordingURL = nil; elapsed = 0; isRecording = false; try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
}
