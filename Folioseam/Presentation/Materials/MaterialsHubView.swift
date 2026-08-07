import SwiftUI

enum MaterialSort: String, CaseIterable, Identifiable, Sendable {
    case name
    case costDesc
    case kind
    case project

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: "Name"
        case .costDesc: "Cost (highest)"
        case .kind: "Kind"
        case .project: "Project"
        }
    }
}

@MainActor
final class MaterialsHubViewModel: ObservableObject {
    @Published var lots: [(MaterialLot, String)] = []
    @Published var needle = ""
    @Published var projectOrder: MaterialSort = .name
    @Published var editing: MaterialLot?
    @Published var isPresentingEditor = false

    private let loadProjects: LoadProjectsUseCase
    private let loadBundle: LoadProjectBundleUseCase
    private let saveMaterial: SaveMaterialUseCase

    init(loadProjects: LoadProjectsUseCase, loadBundle: LoadProjectBundleUseCase, saveMaterial: SaveMaterialUseCase) {
        self.loadProjects = loadProjects
        self.loadBundle = loadBundle
        self.saveMaterial = saveMaterial
    }

    var filteredLots: [(MaterialLot, String)] {
        let trimmed = needle.trimmingCharacters(in: .whitespacesAndNewlines)
        let wideOpen = trimmed.isEmpty
            ? lots
            : lots.filter {
                $0.0.name.localizedCaseInsensitiveContains(trimmed) ||
                $0.0.kind.localizedCaseInsensitiveContains(trimmed) ||
                $0.1.localizedCaseInsensitiveContains(trimmed)
            }
        switch projectOrder {
        case .name:
            return wideOpen.sorted { $0.0.name.localizedCaseInsensitiveCompare($1.0.name) == .orderedAscending }
        case .costDesc:
            return wideOpen.sorted { $0.0.costCents > $1.0.costCents }
        case .kind:
            return wideOpen.sorted { $0.0.kind.localizedCaseInsensitiveCompare($1.0.kind) == .orderedAscending }
        case .project:
            return wideOpen.sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
        }
    }

    var benchEmpty: Bool { lots.isEmpty }
    var needleMiss: Bool { !lots.isEmpty && filteredLots.isEmpty }

    func refresh() async {
        do {
            var collected: [(MaterialLot, String)] = []
            for project in try await loadProjects() {
                let bundle = try await loadBundle(projectID: project.id)
                for lot in bundle.materials {
                    collected.append((lot, project.title))
                }
            }
            lots = collected
        } catch {
            lots = []
        }
    }

    func beginEdit(_ lot: MaterialLot) {
        editing = lot
        isPresentingEditor = true
    }

    func save(_ lot: MaterialLot) async {
        let trimmed = lot.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var normalized = lot
        normalized.name = trimmed
        try? await saveMaterial(normalized)
        isPresentingEditor = false
        editing = nil
        await refresh()
    }
}

struct MaterialsHubView: View {
    @ObservedObject var viewModel: MaterialsHubViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Material lots")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Swatches across open projects.")
                    .foregroundStyle(SeamPalette.ink.opacity(0.65))

                if viewModel.benchEmpty {
                    SeamEmptyState(title: "No materials yet", detail: "Add material lots to a project to see swatches here.")
                        .frame(minHeight: 200)
                } else if viewModel.needleMiss {
                    SeamEmptyState(title: "No matches", detail: "Try a different search or filter.")
                        .frame(minHeight: 200)
                } else {
                    MaterialSwatchStrip(lots: viewModel.filteredLots.map(\.0))
                    ForEach(viewModel.filteredLots, id: \.0.id) { lot, project in
                        Button { viewModel.beginEdit(lot) } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(lot.name).font(.headline)
                                    Text("\(project) · \(lot.kind)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(String(format: "$%.2f", Double(lot.costCents) / 100))
                                    .font(.subheadline.monospaced())
                            }
                            .padding()
                            .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .binderyCanvas()
        .searchable(text: $viewModel.needle, prompt: "Search materials")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort", selection: $viewModel.projectOrder) {
                        ForEach(MaterialSort.allCases) { projectOrder in
                            Text(projectOrder.title).tag(projectOrder)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Sort")
            }
        }
        .task { await viewModel.refresh() }
        .sheet(isPresented: $viewModel.isPresentingEditor) {
            if let editing = viewModel.editing {
                MaterialEditorView(draft: editing) { saved in
                    Task { await viewModel.save(saved) }
                }
            }
        }
    }
}

#Preview("Materials hub") {
    NavigationStack {
        ProjectPreviewHost { container, _ in
            MaterialsHubView(viewModel: container.makeMaterialsViewModel())
        }
    }
}
