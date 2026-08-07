import SwiftUI

/// Exploded binding cross-section — not a letterpress folio.
struct ExplodedBindingCrossSection: View {
    var progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var peel = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    let offset = peel ? CGFloat(index) * 10 : 0
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(layerColor(index))
                        .frame(width: w * 0.72 - CGFloat(index) * 8, height: h * 0.14)
                        .offset(x: offset * 0.4, y: CGFloat(index) * (h * 0.12) - h * 0.22 + offset)
                        .opacity(0.55 + 0.09 * Double(index))
                }
                RoundedRectangle(cornerRadius: 3)
                    .fill(SeamPalette.board)
                    .frame(width: 10, height: h * 0.62)
                    .offset(x: -w * 0.34)
                RoundedRectangle(cornerRadius: 3)
                    .fill(SeamPalette.board.opacity(0.85))
                    .frame(width: 10, height: h * 0.62)
                    .offset(x: w * 0.34)
                Capsule()
                    .fill(SeamPalette.moss)
                    .frame(width: 6, height: h * 0.55 * progress)
                    .offset(x: -w * 0.34)
                    .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.8), value: progress)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if reduceMotion { peel = true }
            else { withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { peel = true } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Exploded binding cross-section")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }

    private func layerColor(_ index: Int) -> Color {
        [SeamPalette.cloth, SeamPalette.cream, Color.white, SeamPalette.thread.opacity(0.35), SeamPalette.moss.opacity(0.35)][index]
    }
}

/// Stitch-topology progress along signatures.
struct StitchTopologyProgress: View {
    var sewnRatio: Double
    @State private var drawn = false

    var body: some View {
        GeometryReader { geo in
            let count = 6
            Path { path in
                let midY = geo.size.height * 0.5
                for i in 0..<count {
                    let x = geo.size.width * (0.08 + Double(i) / Double(count - 1) * 0.84)
                    let up = i % 2 == 0
                    let y = midY + (up ? -18 : 18)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                    path.addEllipse(in: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
                }
            }
            .trim(from: 0, to: drawn ? max(0.05, sewnRatio) : 0)
            .stroke(SeamPalette.moss, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .animation(.easeInOut(duration: 0.9), value: drawn)
            .animation(.easeInOut(duration: 0.5), value: sewnRatio)
        }
        .frame(height: 56)
        .onAppear { drawn = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stitch topology")
        .accessibilityValue("\(Int(sewnRatio * 100)) percent sewn")
    }
}

#Preview("Exploded binding cross-section") {
    ExplodedBindingCrossSection(progress: 0.6)
        .frame(height: 180)
        .padding()
}

#Preview("Stitch topology") {
    StitchTopologyProgress(sewnRatio: 0.4)
        .padding()
}

/// Material swatch strip with subtle flip.
struct MaterialSwatchStrip: View {
    var lots: [MaterialLot]
    @State private var flipped: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(lots) { lot in
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(swatchColor(for: lot.kind))
                            .frame(width: 72, height: 48)
                            .rotation3DEffect(.degrees(flipped == lot.id ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    flipped = flipped == lot.id ? nil : lot.id
                                }
                            }
                        Text(lot.name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SeamPalette.ink)
                            .lineLimit(1)
                        Text(lot.kind)
                            .font(.caption2.monospaced())
                            .foregroundStyle(SeamPalette.ink.opacity(0.6))
                    }
                    .frame(width: 80)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func swatchColor(for kind: String) -> Color {
        switch kind.lowercased() {
        case "cloth": return SeamPalette.cloth
        case "board", "boards": return SeamPalette.board
        case "thread", "linen": return SeamPalette.thread
        case "leather": return Color(red: 0.35, green: 0.22, blue: 0.14)
        default: return SeamPalette.moss.opacity(0.55)
        }
    }
}

struct SpineTabBar: View {
    @Binding var selection: SeamTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SeamTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Capsule()
                            .fill(selection == tab ? SeamPalette.moss : SeamPalette.ink.opacity(0.15))
                            .frame(width: 4, height: selection == tab ? 22 : 12)
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.monospaced())
                    }
                    .foregroundStyle(selection == tab ? SeamPalette.moss : SeamPalette.ink.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            Rectangle()
                .fill(SeamPalette.cream.opacity(0.95))
                .shadow(color: SeamPalette.ink.opacity(0.08), radius: 8, y: -2)
                .overlay(alignment: .top) {
                    Rectangle().fill(SeamPalette.moss.opacity(0.35)).frame(height: 2)
                }
        )
    }
}
