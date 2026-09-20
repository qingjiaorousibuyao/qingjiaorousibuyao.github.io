import AVFoundation
import Combine
import Foundation

enum ChatAudioStartResult {
    case started
    case permissionDenied
    case failed
}

enum ChatAudioFinishResult {
    case recording(filename: String, duration: TimeInterval)
    case tooShort
    case none
}

final class ChatAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var playingMessageID: UUID?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var recordingURL: URL?
    private var interruptionObserver: NSObjectProtocol?

    override init() {
        super.init()
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cancelRecording()
            self?.stopPlayback()
        }
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        recordingTimer?.invalidate()
    }

    func startRecording() async -> ChatAudioStartResult {
        guard !isRecording else { return .started }
        guard await microphonePermissionGranted() else { return .permissionDenied }

        stopPlayback()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let url = ChatAudioStore.makeRecordingURL()
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            guard recorder.prepareToRecord(), recorder.record() else {
                ChatAudioStore.remove(filename: url.lastPathComponent)
                try? session.setActive(false, options: .notifyOthersOnDeactivation)
                return .failed
            }

            self.recorder = recorder
            recordingURL = url
            elapsed = 0
            isRecording = true
            startTimer()
            return .started
        } catch {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            return .failed
        }
    }

    func finishRecording() -> ChatAudioFinishResult {
        guard let recorder, let recordingURL else { return .none }
        let duration = recorder.currentTime
        recorder.stop()
        finishRecordingSession()

        guard duration >= 0.5 else {
            ChatAudioStore.remove(filename: recordingURL.lastPathComponent)
            return .tooShort
        }
        return .recording(filename: recordingURL.lastPathComponent, duration: min(duration, 60))
    }

    func cancelRecording() {
        guard let recorder else { return }
        recorder.stop()
        if let recordingURL {
            ChatAudioStore.remove(filename: recordingURL.lastPathComponent)
        }
        finishRecordingSession()
    }

    func togglePlayback(messageID: UUID, filename: String?) {
        if playingMessageID == messageID {
            stopPlayback()
            return
        }
        guard let url = ChatAudioStore.url(for: filename) else { return }

        stopPlayback()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            guard player.play() else { return }
            self.player = player
            playingMessageID = messageID
        } catch {
            stopPlayback()
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        playingMessageID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.stopPlayback()
        }
    }

    private func microphonePermissionGranted() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    private func startTimer() {
        recordingTimer?.invalidate()
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard let recorder = self.recorder, self.isRecording else {
                self.recordingTimer?.invalidate()
                self.recordingTimer = nil
                return
            }
            self.elapsed = min(recorder.currentTime, 60)
        }
        recordingTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func finishRecordingSession() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recorder = nil
        recordingURL = nil
        elapsed = 0
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
