import SwiftUI

struct ProjectsHomeView: View {
    @ObservedObject var viewModel: ProjectsHomeViewModel
    @EnvironmentObject private var coordinator: BinderyRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image("SpineMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Folioseam")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        Text("Bind, restore, finish books.")
                            .foregroundStyle(SeamPalette.ink.opacity(0.65))
                    }
                    Spacer()
                    Button { coordinator.presentNewProject() } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(SeamPalette.moss)
                    }
                }

                if let first = viewModel.rows.first {
                    ExplodedBindingCrossSection(progress: first.progress)
                        .frame(height: 180)
                        .padding()
                        .background(SeamPalette.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if viewModel.benchEmpty {
                    SeamEmptyState(title: "No projects yet", detail: "Start a binding project to see the exploded cross-section fill in.")
                        .frame(minHeight: 240)
                } else if viewModel.needleMiss {
                    SeamEmptyState(title: "No matches", detail: "Try a different search or filter.")
                        .frame(minHeight: 240)
                } else {
                    ForEach(viewModel.filteredRows) { row in
                        Button { coordinator.openProject(row.project.id) } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(row.project.title)
                                        .font(.headline)
                                        .foregroundStyle(SeamPalette.ink)
                                    Text("\(row.project.bindingStyle) · \(row.project.status.title)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(SeamPalette.ink.opacity(0.6))
                                    ProgressView(value: row.progress)
                                        .tint(SeamPalette.moss)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(SeamPalette.ink.opacity(0.35))
                            }
                            .padding()
                            .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Edit") { coordinator.presentEditProject(row.project.id) }
                            Button("Delete", role: .destructive) {
                                Task { await viewModel.delete(row.project.id) }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .binderyCanvas()
        .searchable(text: $viewModel.needle, prompt: "Search projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort", selection: $viewModel.projectOrder) {
                        ForEach(ProjectSort.allCases) { projectOrder in
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
        .onAppear { Task { await viewModel.refresh() } }
        .onChange(of: coordinator.sheet) { _, newValue in
            if newValue == nil { Task { await viewModel.refresh() } }
        }
        .onChange(of: coordinator.path) { _, _ in
            Task { await viewModel.refresh() }
        }
    }
}

#Preview("Projects home") {
    NavigationStack {
        ProjectPreviewHost { container, _ in
            ProjectsHomeView(viewModel: container.makeProjectsViewModel())
        }
    }
    .environmentObject(BinderyRouter())
}

/// Seeds a demo project in a preview-only container, then builds the requested
/// view once a real project id exists to fetch bundles against.
struct ProjectPreviewHost<Content: View>: View {
    @State private var projectID: UUID?
    private let container = SeamContainer.preview()
    @ViewBuilder private let content: (SeamContainer, UUID) -> Content

    init(@ViewBuilder content: @escaping (SeamContainer, UUID) -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if let projectID {
                content(container, projectID)
            } else {
                ProgressView().task { await seed() }
            }
        }
    }

    private func seed() async {
        await SimulatorBindSeeder.seedIfNeeded(container: container)
        projectID = try? await container.loadProjects().first?.id
    }
}
