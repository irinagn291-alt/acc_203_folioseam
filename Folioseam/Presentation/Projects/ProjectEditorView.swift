import SwiftUI

@MainActor
final class ProjectEditorViewModel: ObservableObject {
    @Published var title = ""
    @Published var client = ""
    @Published var style = "Case binding"
    @Published var status: ProjectStatus = .open
    @Published var notes = ""
    @Published var errorMessage: String?

    private let projectID: UUID?
    private let loadProjects: LoadProjectsUseCase
    private let saveProject: SaveProjectUseCase
    private let saveStage: SaveStageUseCase
    private var openedAt = Date()
    private var existingID: UUID?

    init(projectID: UUID?, loadProjects: LoadProjectsUseCase, saveProject: SaveProjectUseCase, saveStage: SaveStageUseCase) {
        self.projectID = projectID
        self.loadProjects = loadProjects
        self.saveProject = saveProject
        self.saveStage = saveStage
    }

    func load() async {
        guard let projectID else { return }
        if let project = try? await loadProjects().first(where: { $0.id == projectID }) {
            existingID = project.id
            title = project.title
            client = project.clientOrOwner
            style = project.bindingStyle
            status = project.status
            notes = project.notes
            openedAt = project.openedAt
        }
    }

    func save() async -> Bool {
        let id = existingID ?? UUID()
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Title is required."
            return false
        }
        do {
            try await saveProject(BindingProject(
                id: id, title: trimmed, clientOrOwner: client, bindingStyle: style,
                openedAt: openedAt, status: status, notes: notes
            ))
            if existingID == nil {
                for (index, stage) in BindingStage.allCases.enumerated() {
                    try await saveStage(StageTask(
                        id: UUID(), projectId: id, stage: stage, title: stage.title,
                        orderIndex: index, done: false, doneAt: nil
                    ))
                }
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

struct ProjectEditorView: View {
    @ObservedObject var viewModel: ProjectEditorViewModel
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $viewModel.title)
                TextField("Client or owner", text: $viewModel.client)
                TextField("Binding style", text: $viewModel.style)
                Picker("Status", selection: $viewModel.status) {
                    ForEach(ProjectStatus.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle(viewModel.title.isEmpty ? "New project" : "Edit project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close", action: onDone) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { if await viewModel.save() { onDone() } }
                    }
                }
            }
            .task { await viewModel.load() }
        }
    }
}

#Preview("Project editor") {
    ProjectEditorView(
        viewModel: SeamContainer.preview().makeProjectEditorViewModel(projectID: nil),
        onDone: {}
    )
}
