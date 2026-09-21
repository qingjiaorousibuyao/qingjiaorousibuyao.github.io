import SwiftUI

struct VoiceMessageBubble: View {
    let duration: TimeInterval
    let isPlaying: Bool
    let action: () -> Void

    private var width: CGFloat {
        let seconds = min(max(Int(duration.rounded(.up)), 1), 60)
        return CGFloat(86 + ((seconds - 1) / 10) * 28)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: "waveform")
                    .font(.body.weight(.semibold))
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isPlaying)
                Spacer(minLength: 2)
                Text("\(max(1, Int(duration.rounded())))″").font(.subheadline.monospacedDigit()).fixedSize()
            }
            .foregroundStyle(isPlaying ? .primary : .secondary)
            .frame(width: width)
            .frame(minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
