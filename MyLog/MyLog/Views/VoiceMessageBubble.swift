import SwiftUI

struct VoiceMessageBubble: View {
    let duration: TimeInterval
    let isPlaying: Bool
    let action: () -> Void

    private var bubbleWidth: CGFloat {
        min(210, 124 + CGFloat(min(max(duration, 0), 60)) * 1.4)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isPlaying ? Color.primary : Color.secondary)
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isPlaying)
                Image(systemName: "waveform")
                    .font(.subheadline)
                    .foregroundStyle(isPlaying ? Color.primary.opacity(0.82) : Color.secondary)
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isPlaying)
                Spacer(minLength: 4)
                Text("\(max(1, Int(duration.rounded())))″")
                    .font(.subheadline.monospacedDigit())
            }
            .frame(width: bubbleWidth)
            .frame(minHeight: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "停止播放语音" : "播放语音，时长 \(max(1, Int(duration.rounded()))) 秒")
    }
}
