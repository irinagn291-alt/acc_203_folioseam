import Foundation

/// Export/import use cases live next to the export feature UI instead of the
/// shared bindery use case file, since they only serve `ExportHubView`.
struct ExportPayload: Codable, Sendable {
    var project: BindingProject
    var sections: [BookSection]
    var materials: [MaterialLot]
    var stages: [StageTask]
    var conditions: [ConditionRecord]
    var progress: Double
    var materialSpend: Double
    var conditionDelta: Int?
}

struct ExportProjectUseCase: Sendable {
    let loadBundle: LoadProjectBundleUseCase
    let computeProgress: ComputeProjectProgressUseCase

    func json(projectID: UUID) async throws -> Data {
        let bundle = try await loadBundle(projectID: projectID)
        let progress = computeProgress(bundle: bundle)
        let payload = ExportPayload(
            project: bundle.project,
            sections: bundle.sections,
            materials: bundle.materials,
            stages: bundle.stages,
            conditions: bundle.conditions,
            progress: progress.projectProgress,
            materialSpend: progress.materialSpend,
            conditionDelta: progress.conditionDelta
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    func pdf(projectID: UUID) async throws -> Data {
        let bundle = try await loadBundle(projectID: projectID)
        let progress = computeProgress(bundle: bundle)
        return BindPDFRenderer.render(bundle: bundle, progress: progress)
    }
}

/// Reverses `ExportProjectUseCase.json`: decodes the same `ExportPayload` shape and
/// upserts the project and its related records.
struct ImportProjectUseCase: Sendable {
    let projects: BindingProjectRepository
    let sections: BookSectionRepository
    let materials: MaterialLotRepository
    let stages: StageTaskRepository
    let conditions: ConditionRecordRepository

    func callAsFunction(json data: Data) async throws {
        let payload: ExportPayload
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            payload = try decoder.decode(ExportPayload.self, from: data)
        } catch {
            throw SeamImportError.invalidFile
        }
        try Self.validate(payload)

        try await projects.save(payload.project)
        for section in payload.sections {
            try await sections.save(section)
        }
        for lot in payload.materials {
            try await materials.save(lot)
        }
        for stage in payload.stages {
            try await stages.save(stage)
        }
        for condition in payload.conditions {
            try await conditions.save(condition)
        }
    }

    private static func validate(_ payload: ExportPayload) throws {
        guard !payload.project.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SeamImportError.invalidFile
        }
        let projectId = payload.project.id
        guard
            payload.sections.allSatisfy({ $0.projectId == projectId }),
            payload.materials.allSatisfy({ $0.projectId == projectId }),
            payload.stages.allSatisfy({ $0.projectId == projectId }),
            payload.conditions.allSatisfy({ $0.projectId == projectId })
        else {
            throw SeamImportError.invalidFile
        }
    }
}

/// Failure surfaced to the UI when an imported file cannot be trusted.
enum SeamImportError: LocalizedError, Sendable {
    case invalidFile

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            "Could not import file. Check that it is a Folioseam export."
        }
    }
}
