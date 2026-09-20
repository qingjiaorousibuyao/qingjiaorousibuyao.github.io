import SwiftUI

struct VoiceMessageBubble: View {
    let duration: TimeInterval
    let isPlaying: Bool
    let action: () -> Void

    private var bubbleWidth: CGFloat {
        min(max(96, 94 + CGFloat(duration) * 1.6), 196)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(.body.weight(.semibold))
                Spacer(minLength: 4)
                Text("\(max(1, Int(duration.rounded())))″")
                    .font(.subheadline.monospacedDigit())
            }
            .frame(width: bubbleWidth)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "停止播放语音" : "播放语音，时长 \(max(1, Int(duration.rounded()))) 秒")
    }
}
