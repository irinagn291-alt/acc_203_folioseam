import SwiftUI

enum SeamPalette {
    static let moss = Color(red: 0.349, green: 0.420, blue: 0.278)
    static let cream = Color(red: 0.949, green: 0.941, blue: 0.902)
    static let ink = Color(red: 0.122, green: 0.141, blue: 0.102)
    static let board = Color(red: 0.45, green: 0.36, blue: 0.24)
    static let thread = Color(red: 0.32, green: 0.40, blue: 0.27)
    static let cloth = Color(red: 0.55, green: 0.48, blue: 0.38)

    static func stageColor(_ stage: BindingStage) -> Color {
        let colors: [Color] = [
            Color(red: 0.45, green: 0.55, blue: 0.35),
            Color(red: 0.42, green: 0.50, blue: 0.32),
            Color(red: 0.48, green: 0.45, blue: 0.30),
            Color(red: 0.50, green: 0.40, blue: 0.28),
            Color(red: 0.52, green: 0.38, blue: 0.26),
            Color(red: 0.45, green: 0.34, blue: 0.24),
            Color(red: 0.38, green: 0.30, blue: 0.22)
        ]
        let index = BindingStage.allCases.firstIndex(of: stage) ?? 0
        return colors[index]
    }
}

extension View {
    func binderyCanvas() -> some View {
        background(
            LinearGradient(
                colors: [SeamPalette.cream, SeamPalette.cream.opacity(0.92), Color(red: 0.93, green: 0.91, blue: 0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

struct SeamEmptyState: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 12) {
            Image("EmptyBindery")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(title)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(SeamPalette.ink)
            Text(detail)
                .font(.body)
                .foregroundStyle(SeamPalette.ink.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
