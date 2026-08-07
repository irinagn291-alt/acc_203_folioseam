import Foundation

struct LoadProjectsUseCase: Sendable {
    let repository: BindingProjectRepository
    func callAsFunction() async throws -> [BindingProject] { try await repository.fetchAll() }
}

struct SaveProjectUseCase: Sendable {
    let repository: BindingProjectRepository
    func callAsFunction(_ project: BindingProject) async throws { try await repository.save(project) }
}

struct DeleteProjectUseCase: Sendable {
    let repository: BindingProjectRepository
    func callAsFunction(id: UUID) async throws { try await repository.delete(id: id) }
}

struct LoadProjectBundleUseCase: Sendable {
    let projects: BindingProjectRepository
    let sections: BookSectionRepository
    let materials: MaterialLotRepository
    let stages: StageTaskRepository
    let conditions: ConditionRecordRepository

    func callAsFunction(projectID: UUID) async throws -> ProjectBundle {
        guard let project = try await projects.fetch(id: projectID) else { throw SeamError.notFound }
        return ProjectBundle(
            project: project,
            sections: try await sections.fetch(projectId: projectID),
            materials: try await materials.fetch(projectId: projectID),
            stages: try await stages.fetch(projectId: projectID),
            conditions: try await conditions.fetch(projectId: projectID)
        )
    }
}

struct SaveSectionUseCase: Sendable {
    let repository: BookSectionRepository
    func callAsFunction(_ section: BookSection) async throws { try await repository.save(section) }
}

struct DeleteSectionUseCase: Sendable {
    let repository: BookSectionRepository
    func callAsFunction(id: UUID) async throws { try await repository.delete(id: id) }
}

struct SaveMaterialUseCase: Sendable {
    let repository: MaterialLotRepository
    func callAsFunction(_ lot: MaterialLot) async throws { try await repository.save(lot) }
}

struct DeleteMaterialUseCase: Sendable {
    let repository: MaterialLotRepository
    func callAsFunction(id: UUID) async throws { try await repository.delete(id: id) }
}

struct SaveStageUseCase: Sendable {
    let repository: StageTaskRepository
    func callAsFunction(_ task: StageTask) async throws { try await repository.save(task) }
}

struct SaveConditionUseCase: Sendable {
    let repository: ConditionRecordRepository
    func callAsFunction(_ record: ConditionRecord) async throws { try await repository.save(record) }
}

struct DeleteConditionUseCase: Sendable {
    let repository: ConditionRecordRepository
    func callAsFunction(id: UUID) async throws { try await repository.delete(id: id) }
}

struct ComputeProjectProgressUseCase: Sendable {
    func callAsFunction(bundle: ProjectBundle) -> ProjectProgress {
        let doneStages = bundle.stages.filter(\.done).count
        let stage = BindMath.stageProgress(doneStages: doneStages, totalStages: bundle.stages.count)
        let sewn = bundle.sections.filter(\.sewn).count
        let section = BindMath.sectionProgress(sewnSections: sewn, totalSections: bundle.sections.count)
        let project = BindMath.projectProgress(
            stageProgress: stage,
            sectionProgress: section,
            hasSections: !bundle.sections.isEmpty
        )
        let before = bundle.conditions.first(where: { $0.phase == .before })?.score
        let after = bundle.conditions.first(where: { $0.phase == .after })?.score
        return ProjectProgress(
            stageProgress: stage,
            sectionProgress: section,
            projectProgress: project,
            conditionDelta: BindMath.conditionDelta(before: before, after: after),
            materialSpend: BindMath.materialSpend(costCents: bundle.materials.map(\.costCents))
        )
    }
}

struct BinderyStatsSnapshot: Sendable {
    struct StatusCount: Identifiable, Sendable {
        var status: ProjectStatus
        var count: Int
        var id: String { status.rawValue }
    }

    struct StageCount: Identifiable, Sendable {
        var stage: BindingStage
        var done: Int
        var total: Int
        var id: String { stage.rawValue }
    }

    var totalProjects: Int
    var statusCounts: [StatusCount]
    var totalMaterialLots: Int
    var materialSpend: Double
    var totalSections: Int
    var sewnSections: Int
    var sectionProgress: Double
    var stageCounts: [StageCount]
}

/// Aggregates project counts by stage, material lots, and sewn-section progress across the bench.
struct LoadBinderyStatsUseCase: Sendable {
    let loadProjects: LoadProjectsUseCase
    let loadBundle: LoadProjectBundleUseCase

    func callAsFunction() async throws -> BinderyStatsSnapshot {
        let projects = try await loadProjects()
        var statusTally: [ProjectStatus: Int] = [:]
        var totalMaterialLots = 0
        var materialSpendCents = 0
        var totalSections = 0
        var sewnSections = 0
        var stageDone: [BindingStage: Int] = [:]
        var stageTotal: [BindingStage: Int] = [:]

        for project in projects {
            statusTally[project.status, default: 0] += 1
            guard let bundle = try? await loadBundle(projectID: project.id) else { continue }
            totalMaterialLots += bundle.materials.count
            materialSpendCents += bundle.materials.map(\.costCents).reduce(0, +)
            totalSections += bundle.sections.count
            sewnSections += bundle.sections.filter(\.sewn).count
            for task in bundle.stages {
                stageTotal[task.stage, default: 0] += 1
                if task.done { stageDone[task.stage, default: 0] += 1 }
            }
        }

        let statusCounts = ProjectStatus.allCases.map {
            BinderyStatsSnapshot.StatusCount(status: $0, count: statusTally[$0, default: 0])
        }
        let stageCounts = BindingStage.allCases.map {
            BinderyStatsSnapshot.StageCount(stage: $0, done: stageDone[$0, default: 0], total: stageTotal[$0, default: 0])
        }

        return BinderyStatsSnapshot(
            totalProjects: projects.count,
            statusCounts: statusCounts,
            totalMaterialLots: totalMaterialLots,
            materialSpend: Double(materialSpendCents) / 100.0,
            totalSections: totalSections,
            sewnSections: sewnSections,
            sectionProgress: totalSections == 0 ? 0 : Double(sewnSections) / Double(totalSections),
            stageCounts: stageCounts
        )
    }
}

@MainActor
struct ResetBinderyDataUseCase {
    let projects: BindingProjectRepository
    let introSpine: SeamOnboardingPort

    func callAsFunction() async throws {
        for project in try await projects.fetchAll() {
            try await projects.delete(id: project.id)
        }
        introSpine.isCompleted = false
    }
}
