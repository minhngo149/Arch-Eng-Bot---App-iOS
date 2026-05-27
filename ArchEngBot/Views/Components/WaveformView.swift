import SwiftUI

struct WaveformView: View {
    let levels: [CGFloat]
    let isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            let barCount = 48
            let displayLevels = paddedLevels(targetCount: barCount)
            let spacing: CGFloat = 3
            let barWidth = max(2, (proxy.size.width - spacing * CGFloat(barCount - 1)) / CGFloat(barCount))

            HStack(alignment: .center, spacing: spacing) {
                ForEach(displayLevels.indices, id: \.self) { index in
                    let level = displayLevels[index]
                    Capsule()
                        .fill(barColor(for: level))
                        .frame(width: barWidth,
                               height: max(4, level * proxy.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.linear(duration: 0.08), value: displayLevels)
        }
    }

    private func paddedLevels(targetCount: Int) -> [CGFloat] {
        if levels.count >= targetCount {
            return Array(levels.suffix(targetCount))
        }
        return Array(repeating: 0.05, count: targetCount - levels.count) + levels
    }

    private func barColor(for level: CGFloat) -> Color {
        guard isActive else { return Color.gray.opacity(0.25) }
        if level > 0.7 { return .red }
        if level > 0.4 { return .orange }
        return .blue
    }
}

#Preview {
    VStack(spacing: 20) {
        WaveformView(levels: (0..<30).map { _ in CGFloat.random(in: 0.1...0.9) },
                     isActive: true)
            .frame(height: 60)
        WaveformView(levels: [], isActive: false)
            .frame(height: 60)
    }
    .padding()
}
