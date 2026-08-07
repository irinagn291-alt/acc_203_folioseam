import Combine
import Foundation

struct ProjectRow: Identifiable, Equatable {
    var id: UUID { project.id }
    var project: BindingProject
    var progress: Double
}

enum ProjectSort: String, CaseIterable, Identifiable, Sendable {
    case dateOpenedNewest
    case name
    case progressDesc
    case status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dateOpenedNewest: "Opened (newest)"
        case .name: "Name"
        case .progressDesc: "Progress (most complete)"
        case .status: "Status"
        }
    }
}

@MainActor
final class ProjectsHomeViewModel: ObservableObject {
    @Published var rows: [ProjectRow] = []
    @Published var errorMessage: String?
    @Published var needle = ""
    @Published var projectOrder: ProjectSort = .dateOpenedNewest

    private let loadProjects: LoadProjectsUseCase
    private let deleteProject: DeleteProjectUseCase
    private let loadBundle: LoadProjectBundleUseCase
    private let computeProgress: ComputeProjectProgressUseCase

    init(
        loadProjects: LoadProjectsUseCase,
        deleteProject: DeleteProjectUseCase,
        loadBundle: LoadProjectBundleUseCase,
        computeProgress: ComputeProjectProgressUseCase
    ) {
        self.loadProjects = loadProjects
        self.deleteProject = deleteProject
        self.loadBundle = loadBundle
        self.computeProgress = computeProgress
    }

    var filteredRows: [ProjectRow] {
        let trimmed = needle.trimmingCharacters(in: .whitespacesAndNewlines)
        let wideOpen = trimmed.isEmpty
            ? rows
            : rows.filter {
                $0.project.title.localizedCaseInsensitiveContains(trimmed) ||
                $0.project.clientOrOwner.localizedCaseInsensitiveContains(trimmed) ||
                $0.project.bindingStyle.localizedCaseInsensitiveContains(trimmed)
            }
        switch projectOrder {
        case .dateOpenedNewest:
            return wideOpen.sorted { $0.project.openedAt > $1.project.openedAt }
        case .name:
            return wideOpen.sorted { $0.project.title.localizedCaseInsensitiveCompare($1.project.title) == .orderedAscending }
        case .progressDesc:
            return wideOpen.sorted { $0.progress > $1.progress }
        case .status:
            return wideOpen.sorted { $0.project.status.rawValue < $1.project.status.rawValue }
        }
    }

    var benchEmpty: Bool { rows.isEmpty }
    var needleMiss: Bool { !rows.isEmpty && filteredRows.isEmpty }

    func refresh() async {
        do {
            let projects = try await loadProjects()
            var built: [ProjectRow] = []
            for project in projects {
                let bundle = try await loadBundle(projectID: project.id)
                let progress = computeProgress(bundle: bundle)
                built.append(ProjectRow(project: project, progress: progress.projectProgress))
            }
            rows = built
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ id: UUID) async {
        do {
            try await deleteProject(id: id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
