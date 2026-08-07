import Foundation

enum BindingStage: String, CaseIterable, Codable, Sendable, Identifiable {
    case fold, sew, glue, boards, covering, finishing, press

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fold: return "Fold"
        case .sew: return "Sew"
        case .glue: return "Glue"
        case .boards: return "Boards"
        case .covering: return "Covering"
        case .finishing: return "Finishing"
        case .press: return "Press"
        }
    }
}

enum ProjectStatus: String, CaseIterable, Codable, Sendable {
    case open, inProgress, finished, archived

    var title: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In progress"
        case .finished: return "Finished"
        case .archived: return "Archived"
        }
    }
}

enum ConditionPhase: String, CaseIterable, Codable, Sendable {
    case before, during, after

    var title: String {
        switch self {
        case .before: return "Before"
        case .during: return "During"
        case .after: return "After"
        }
    }
}

struct BindingProject: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var title: String
    var clientOrOwner: String
    var bindingStyle: String
    var openedAt: Date
    var status: ProjectStatus
    var notes: String
}

struct BookSection: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var projectId: UUID
    var name: String
    var pageCount: Int
    var orderIndex: Int
    var sewn: Bool
}

struct MaterialLot: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var projectId: UUID
    var kind: String
    var name: String
    var quantity: Double
    var unit: String
    var costCents: Int
    var notes: String
}

struct StageTask: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var projectId: UUID
    var stage: BindingStage
    var title: String
    var orderIndex: Int
    var done: Bool
    var doneAt: Date?
}

struct ConditionRecord: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var projectId: UUID
    var phase: ConditionPhase
    var score: Int
    var notes: String
    var photoPath: String?
    var recordedAt: Date
}

struct ProjectBundle: Equatable, Sendable {
    var project: BindingProject
    var sections: [BookSection]
    var materials: [MaterialLot]
    var stages: [StageTask]
    var conditions: [ConditionRecord]
}

struct ProjectProgress: Equatable, Sendable {
    var stageProgress: Double
    var sectionProgress: Double
    var projectProgress: Double
    var conditionDelta: Int?
    var materialSpend: Double
}

enum SeamError: Error, Equatable, LocalizedError, Sendable {
    case storeFailure(String)
    case notFound
    case validation(String)

    var errorDescription: String? {
        switch self {
        case .storeFailure(let message): return message
        case .notFound: return "Item not found."
        case .validation(let message): return message
        }
    }
}

struct AppPreferences: Equatable, Sendable {
    var showMaterialCosts: Bool
    var defaultBindingStyle: String
}
