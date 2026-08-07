import Combine
import Foundation

enum SeamTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case bench, materials, stats, export, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bench: return "Bench"
        case .materials: return "Lots"
        case .stats: return "Stats"
        case .export: return "Export"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .bench: return "book.closed"
        case .materials: return "square.grid.2x2"
        case .stats: return "chart.bar.xaxis"
        case .export: return "square.and.arrow.up"
        case .settings: return "gearshape"
        }
    }
}

enum SeamRoute: Hashable, Sendable {
    case project(UUID)
}

enum SeamSheet: Identifiable, Hashable, Sendable {
    case newProject
    case editProject(UUID)

    var id: String {
        switch self {
        case .newProject: return "new"
        case .editProject(let id): return "edit-\(id.uuidString)"
        }
    }
}

@MainActor
final class BinderyRouter: ObservableObject {
    @Published var selectedTab: SeamTab = .bench
    @Published var path: [SeamRoute] = []
    @Published var sheet: SeamSheet?

    func openProject(_ id: UUID) { path.append(.project(id)) }
    func presentNewProject() { sheet = .newProject }
    func presentEditProject(_ id: UUID) { sheet = .editProject(id) }
    func dismissSheet() { sheet = nil }
    func pop() { if !path.isEmpty { path.removeLast() } }
}
