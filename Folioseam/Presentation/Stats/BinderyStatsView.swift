import SwiftUI

@MainActor
final class BinderyStatsViewModel: ObservableObject {
    @Published var snapshot: BinderyStatsSnapshot?
    @Published var errorMessage: String?

    private let loadStats: LoadBinderyStatsUseCase

    init(loadStats: LoadBinderyStatsUseCase) {
        self.loadStats = loadStats
    }

    func refresh() async {
        do {
            snapshot = try await loadStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BinderyStatsView: View {
    @ObservedObject var viewModel: BinderyStatsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Bindery statistics")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Counts, materials, and sewing progress across the bench.")
                    .foregroundStyle(SeamPalette.ink.opacity(0.65))

                if let snapshot = viewModel.snapshot {
                    if snapshot.totalProjects == 0 {
                        SeamEmptyState(
                            title: "No projects yet",
                            detail: "Start a binding project to see bench statistics build up."
                        )
                        .frame(minHeight: 260)
                    } else {
                        summaryGrid(snapshot)
                        statusSection(snapshot)
                        sectionProgressCard(snapshot)
                        stageSection(snapshot)
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding(20)
        }
        .binderyCanvas()
        .task { await viewModel.refresh() }
        .onAppear { Task { await viewModel.refresh() } }
    }

    private func summaryGrid(_ s: BinderyStatsSnapshot) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metric("Projects", "\(s.totalProjects)")
            metric("Material lots", "\(s.totalMaterialLots)")
            metric("Material spend", String(format: "$%.2f", s.materialSpend))
            metric("Sections sewn", "\(s.sewnSections)/\(s.totalSections)")
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.monospaced())
                .foregroundStyle(SeamPalette.ink.opacity(0.55))
            Text(value)
                .font(.title3.monospaced().weight(.semibold))
                .foregroundStyle(SeamPalette.moss)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func statusSection(_ s: BinderyStatsSnapshot) -> some View {
        let maxCount = max(1, s.statusCounts.map(\.count).max() ?? 1)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Projects by stage of life")
                .font(.headline)
                .foregroundStyle(SeamPalette.ink)
            ForEach(s.statusCounts) { row in
                barRow(
                    label: row.status.title,
                    fraction: Double(row.count) / Double(maxCount),
                    trailing: "\(row.count)",
                    color: SeamPalette.moss,
                    accessibilityText: "\(row.status.title): \(row.count) projects"
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sectionProgressCard(_ s: BinderyStatsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sewn sections across all projects")
                    .font(.headline)
                    .foregroundStyle(SeamPalette.ink)
                Spacer()
                Text(String(format: "%.0f%%", s.sectionProgress * 100))
                    .font(.subheadline.monospaced().weight(.semibold))
                    .foregroundStyle(SeamPalette.moss)
            }
            StitchTopologyProgress(sewnRatio: s.sectionProgress)
        }
        .padding(16)
        .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sewn sections \(Int(s.sectionProgress * 100)) percent, \(s.sewnSections) of \(s.totalSections)")
    }

    private func stageSection(_ s: BinderyStatsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stage-task completion")
                .font(.headline)
                .foregroundStyle(SeamPalette.ink)
            ForEach(s.stageCounts) { row in
                let fraction = row.total == 0 ? 0 : Double(row.done) / Double(row.total)
                barRow(
                    label: row.stage.title,
                    fraction: fraction,
                    trailing: "\(row.done)/\(row.total)",
                    color: SeamPalette.stageColor(row.stage),
                    accessibilityText: "\(row.stage.title): \(row.done) of \(row.total) tasks done"
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func barRow(label: String, fraction: Double, trailing: String, color: Color, accessibilityText: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SeamPalette.ink)
                Spacer()
                Text(trailing)
                    .font(.caption.monospaced())
                    .foregroundStyle(SeamPalette.ink.opacity(0.6))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SeamPalette.ink.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(1, fraction)))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}

#Preview("Bindery stats") {
    NavigationStack {
        ProjectPreviewHost { container, _ in
            BinderyStatsView(viewModel: container.makeStatsViewModel())
        }
    }
}
