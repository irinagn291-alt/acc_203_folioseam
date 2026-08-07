import Foundation

protocol BindingProjectRepository: Sendable {
    func fetchAll() async throws -> [BindingProject]
    func fetch(id: UUID) async throws -> BindingProject?
    func save(_ project: BindingProject) async throws
    func delete(id: UUID) async throws
    func count() async throws -> Int
}

protocol BookSectionRepository: Sendable {
    func fetch(projectId: UUID) async throws -> [BookSection]
    func save(_ section: BookSection) async throws
    func delete(id: UUID) async throws
}

protocol MaterialLotRepository: Sendable {
    func fetch(projectId: UUID) async throws -> [MaterialLot]
    func fetchAll() async throws -> [MaterialLot]
    func save(_ lot: MaterialLot) async throws
    func delete(id: UUID) async throws
}

protocol StageTaskRepository: Sendable {
    func fetch(projectId: UUID) async throws -> [StageTask]
    func save(_ task: StageTask) async throws
    func delete(id: UUID) async throws
}

protocol ConditionRecordRepository: Sendable {
    func fetch(projectId: UUID) async throws -> [ConditionRecord]
    func save(_ record: ConditionRecord) async throws
    func delete(id: UUID) async throws
}

protocol SeamOnboardingPort: AnyObject, Sendable {
    var isCompleted: Bool { get set }
}

protocol PreferencesStore: AnyObject, Sendable {
    var preferences: AppPreferences { get set }
}
