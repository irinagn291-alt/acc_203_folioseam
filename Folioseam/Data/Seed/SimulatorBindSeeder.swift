import Foundation

enum SimulatorBindSeeder {
    @MainActor
    static func seedIfNeeded(container: SeamContainer) async {
        #if targetEnvironment(simulator)
        do {
            if try await container.projectRepository.count() > 0 { return }
            let projectID = UUID()
            let project = BindingProject(
                id: projectID,
                title: "Oak folio restoration",
                clientOrOwner: "Studio demo",
                bindingStyle: "Case binding",
                openedAt: Date().addingTimeInterval(-86400 * 3),
                status: .inProgress,
                notes: "Demo project seeded for the simulator."
            )
            try await container.saveProject(project)
            for (index, stage) in BindingStage.allCases.enumerated() {
                try await container.saveStage(StageTask(
                    id: UUID(), projectId: projectID, stage: stage,
                    title: stage.title, orderIndex: index,
                    done: index < 2, doneAt: index < 2 ? Date() : nil
                ))
            }
            try await container.saveSection(BookSection(
                id: UUID(), projectId: projectID, name: "Text block A", pageCount: 64, orderIndex: 0, sewn: true
            ))
            try await container.saveSection(BookSection(
                id: UUID(), projectId: projectID, name: "Endpapers", pageCount: 8, orderIndex: 1, sewn: false
            ))
            try await container.saveMaterial(MaterialLot(
                id: UUID(), projectId: projectID, kind: "Cloth", name: "Moss buckram",
                quantity: 1.2, unit: "m", costCents: 1850, notes: "Spine wrap"
            ))
            try await container.saveCondition(ConditionRecord(
                id: UUID(), projectId: projectID, phase: .before, score: 42,
                notes: "Loose signatures, faded cloth.", photoPath: nil, recordedAt: Date().addingTimeInterval(-86400)
            ))
        } catch {
            // Demo seed is best-effort.
        }
        #endif
    }
}
