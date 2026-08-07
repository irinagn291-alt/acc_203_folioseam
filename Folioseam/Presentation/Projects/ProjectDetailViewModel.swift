import Combine
import Foundation
import Photos
import PhotosUI
import SwiftUI

@MainActor
final class ProjectDetailViewModel: ObservableObject {
    @Published var bundle: ProjectBundle?
    @Published var progress: ProjectProgress?
    @Published var errorMessage: String?
    @Published var photoDeniedMessage: String?
    @Published var newSectionName = ""
    @Published var newMaterialName = ""
    @Published var conditionNotes = ""
    @Published var conditionScore = 50
    @Published var conditionPhase: ConditionPhase = .during
    @Published var editingSection: BookSection?
    @Published var isPresentingSectionEditor = false
    @Published var editingMaterial: MaterialLot?
    @Published var isPresentingMaterialEditor = false

    let projectID: UUID
    private let loadBundle: LoadProjectBundleUseCase
    private let saveStage: SaveStageUseCase
    private let saveSection: SaveSectionUseCase
    private let saveMaterial: SaveMaterialUseCase
    private let saveCondition: SaveConditionUseCase
    private let deleteSection: DeleteSectionUseCase
    private let deleteMaterial: DeleteMaterialUseCase
    private let deleteCondition: DeleteConditionUseCase
    private let computeProgress: ComputeProjectProgressUseCase

    init(
        projectID: UUID,
        loadBundle: LoadProjectBundleUseCase,
        saveStage: SaveStageUseCase,
        saveSection: SaveSectionUseCase,
        saveMaterial: SaveMaterialUseCase,
        saveCondition: SaveConditionUseCase,
        deleteSection: DeleteSectionUseCase,
        deleteMaterial: DeleteMaterialUseCase,
        deleteCondition: DeleteConditionUseCase,
        computeProgress: ComputeProjectProgressUseCase
    ) {
        self.projectID = projectID
        self.loadBundle = loadBundle
        self.saveStage = saveStage
        self.saveSection = saveSection
        self.saveMaterial = saveMaterial
        self.saveCondition = saveCondition
        self.deleteSection = deleteSection
        self.deleteMaterial = deleteMaterial
        self.deleteCondition = deleteCondition
        self.computeProgress = computeProgress
    }

    func refresh() async {
        do {
            let bundle = try await loadBundle(projectID: projectID)
            self.bundle = bundle
            progress = computeProgress(bundle: bundle)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleStage(_ task: StageTask) async {
        var updated = task
        updated.done.toggle()
        updated.doneAt = updated.done ? Date() : nil
        do {
            try await saveStage(updated)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSection(_ section: BookSection) async {
        var updated = section
        updated.sewn.toggle()
        do {
            try await saveSection(updated)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addSection() async {
        let name = newSectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let order = (bundle?.sections.map(\.orderIndex).max() ?? -1) + 1
        do {
            try await saveSection(BookSection(id: UUID(), projectId: projectID, name: name, pageCount: 16, orderIndex: order, sewn: false))
            newSectionName = ""
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func beginEditSection(_ section: BookSection) {
        editingSection = section
        isPresentingSectionEditor = true
    }

    func saveSectionEdit(_ section: BookSection) async {
        let trimmed = section.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var normalized = section
        normalized.name = trimmed
        do {
            try await saveSection(normalized)
        } catch {
            errorMessage = error.localizedDescription
        }
        isPresentingSectionEditor = false
        editingSection = nil
        await refresh()
    }

    func beginEditMaterial(_ lot: MaterialLot) {
        editingMaterial = lot
        isPresentingMaterialEditor = true
    }

    func saveMaterialEdit(_ lot: MaterialLot) async {
        let trimmed = lot.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var normalized = lot
        normalized.name = trimmed
        do {
            try await saveMaterial(normalized)
        } catch {
            errorMessage = error.localizedDescription
        }
        isPresentingMaterialEditor = false
        editingMaterial = nil
        await refresh()
    }

    func addMaterial() async {
        let name = newMaterialName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try await saveMaterial(MaterialLot(id: UUID(), projectId: projectID, kind: "Cloth", name: name, quantity: 1, unit: "m", costCents: 0, notes: ""))
            newMaterialName = ""
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCondition(photoPath: String?) async {
        do {
            try await saveCondition(ConditionRecord(
                id: UUID(), projectId: projectID, phase: conditionPhase,
                score: conditionScore, notes: conditionNotes, photoPath: photoPath, recordedAt: Date()
            ))
            conditionNotes = ""
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeCondition(_ record: ConditionRecord) async {
        do {
            try await deleteCondition(id: record.id)
            if let path = record.photoPath {
                try? FileManager.default.removeItem(atPath: path)
            }
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func preparePhotoAttachment() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized, .limited:
            photoDeniedMessage = nil
            return true
        default:
            photoDeniedMessage = "Photos access denied. You can still save condition scores and notes without an image."
            return false
        }
    }
}
