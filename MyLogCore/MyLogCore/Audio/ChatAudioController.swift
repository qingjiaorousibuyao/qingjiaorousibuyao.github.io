import AVFoundation
import Foundation

enum RecordingStart { case started, denied, failed }
enum RecordingFinish { case saved(path: String, duration: TimeInterval), tooShort, none }

@MainActor
final class ChatAudioController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var playingID: UUID?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var recordingURL: URL?

    func start() async -> RecordingStart {
        guard !isRecording else { return .started }
        let permission: Bool
        switch AVAudioApplication.shared.recordPermission {
        case .granted: permission = true
        case .denied: permission = false
        case .undetermined:
            permission = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
            }
        @unknown default: permission = false
        }
        guard permission else { return .denied }
        stopPlayback()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            let url = MediaStore.makeAudioURL()
            let recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            guard recorder.prepareToRecord(), recorder.record() else { return .failed }
            self.recorder = recorder; recordingURL = url; elapsed = 0; isRecording = true
            let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let recorder = self.recorder else { return }
                    self.elapsed = min(recorder.currentTime, 60)
                }
            }
            self.timer = timer; RunLoop.main.add(timer, forMode: .common)
            return .started
        } catch { return .failed }
    }

    func finish() -> RecordingFinish {
        guard let recorder, let url = recordingURL else { return .none }
        let duration = recorder.currentTime
        recorder.stop(); endSession()
        guard duration >= 0.5 else { try? FileManager.default.removeItem(at: url); return .tooShort }
        return .saved(path: MediaStore.relativeAudioPath(for: url), duration: min(duration, 60))
    }

    func cancel() {
        recorder?.stop()
        if let recordingURL { try? FileManager.default.removeItem(at: recordingURL) }
        endSession()
    }

    func toggle(messageID: UUID, path: String?) {
        if playingID == messageID { stopPlayback(); return }
        guard let url = MediaStore.audioURL(path: path) else { return }
        stopPlayback()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio); try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url); player.delegate = self; player.prepareToPlay()
            guard player.play() else { return }
            self.player = player; playingID = messageID
        } catch { stopPlayback() }
    }

    func stopPlayback() {
        player?.stop(); player = nil; playingID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.stopPlayback() }
    }

    private func endSession() {
        timer?.invalidate(); timer = nil; recorder = nil; recordingURL = nil; isRecording = false; elapsed = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
