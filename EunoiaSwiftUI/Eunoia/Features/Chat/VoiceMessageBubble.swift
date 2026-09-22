import SwiftUI

struct VoiceMessageBubble: View {
    let duration: TimeInterval; let isPlaying: Bool; let action: () -> Void
    private var width: CGFloat { CGFloat(86 + ((min(max(Int(duration.rounded(.up)), 1), 60) - 1) / 10) * 28) }
    var body: some View { Button(action: action) { HStack(spacing: 9) { Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill"); Image(systemName: "waveform"); Spacer(minLength: 4); Text("\(max(1, Int(duration.rounded())))″").monospacedDigit() }.frame(width: width, minHeight: 36) }.buttonStyle(.plain) }
}
