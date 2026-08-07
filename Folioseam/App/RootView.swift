import SwiftUI

/// Root shell: onboarding gate, custom spine navigation, navigation stack.
struct RootView: View {
    @StateObject private var binder = BinderyRouter()
    @State private var showOnboarding: Bool?
    @State private var didSeed = false

    private let container: SeamContainer

    init(container: SeamContainer) {
        self.container = container
    }

    var body: some View {
        Group {
            if showOnboarding == true {
                SeamIntroView(viewModel: container.makeOnboardingViewModel()) {
                    showOnboarding = false
                }
            } else if showOnboarding == false {
                mainShell
            } else {
                Color.clear.binderyCanvas()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await decideFirstScreen() }
        .environmentObject(binder)
    }

    private var mainShell: some View {
        NavigationStack(path: $binder.path) {
            VStack(spacing: 0) {
                // Switch — not ZStack+opacity — so searchable/toolbar from idle tabs cannot shrink the shell.
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                SpineTabBar(selection: $binder.selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationDestination(for: SeamRoute.self) { route in
                switch route {
                case .project(let id):
                    ProjectDetailView(viewModel: container.makeProjectDetailViewModel(projectID: id))
                }
            }
        }
        .tint(SeamPalette.moss)
        .sheet(item: $binder.sheet) { sheet in
            switch sheet {
            case .newProject:
                ProjectEditorView(viewModel: container.makeProjectEditorViewModel(projectID: nil)) {
                    binder.dismissSheet()
                }
            case .editProject(let id):
                ProjectEditorView(viewModel: container.makeProjectEditorViewModel(projectID: id)) {
                    binder.dismissSheet()
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch binder.selectedTab {
        case .bench:
            ProjectsHomeView(viewModel: container.makeProjectsViewModel())
        case .materials:
            MaterialsHubView(viewModel: container.makeMaterialsViewModel())
        case .stats:
            BinderyStatsView(viewModel: container.makeStatsViewModel())
        case .export:
            ExportHubView(viewModel: container.makeExportViewModel())
        case .settings:
            SettingsView(viewModel: container.makeSettingsViewModel()) {
                showOnboarding = true
            }
        }
    }

    private func decideFirstScreen() async {
        if !didSeed {
            didSeed = true
            await SimulatorBindSeeder.seedIfNeeded(container: container)
        }
        showOnboarding = !container.introSpine.isCompleted
    }
}

#Preview("Root") {
    RootView(container: SeamContainer.preview())
}
