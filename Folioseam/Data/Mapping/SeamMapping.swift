import Foundation

enum SeamMapping {
    static func project(from e: BindingProjectEntity) -> BindingProject {
        BindingProject(
            id: e.id, title: e.title, clientOrOwner: e.clientOrOwner, bindingStyle: e.bindingStyle,
            openedAt: e.openedAt, status: ProjectStatus(rawValue: e.status) ?? .open, notes: e.notes
        )
    }

    static func apply(_ m: BindingProject, to e: BindingProjectEntity) {
        e.id = m.id; e.title = m.title; e.clientOrOwner = m.clientOrOwner; e.bindingStyle = m.bindingStyle
        e.openedAt = m.openedAt; e.status = m.status.rawValue; e.notes = m.notes
    }

    static func section(from e: BookSectionEntity) -> BookSection {
        BookSection(id: e.id, projectId: e.projectId, name: e.name, pageCount: Int(e.pageCount), orderIndex: Int(e.orderIndex), sewn: e.sewn)
    }

    static func apply(_ m: BookSection, to e: BookSectionEntity) {
        e.id = m.id; e.projectId = m.projectId; e.name = m.name; e.pageCount = Int32(m.pageCount)
        e.orderIndex = Int32(m.orderIndex); e.sewn = m.sewn
    }

    static func material(from e: MaterialLotEntity) -> MaterialLot {
        MaterialLot(id: e.id, projectId: e.projectId, kind: e.kind, name: e.name, quantity: e.quantity, unit: e.unit, costCents: Int(e.costCents), notes: e.notes)
    }

    static func apply(_ m: MaterialLot, to e: MaterialLotEntity) {
        e.id = m.id; e.projectId = m.projectId; e.kind = m.kind; e.name = m.name
        e.quantity = m.quantity; e.unit = m.unit; e.costCents = Int32(m.costCents); e.notes = m.notes
    }

    static func stage(from e: StageTaskEntity) -> StageTask {
        StageTask(id: e.id, projectId: e.projectId, stage: BindingStage(rawValue: e.stage) ?? .fold, title: e.title, orderIndex: Int(e.orderIndex), done: e.done, doneAt: e.doneAt)
    }

    static func apply(_ m: StageTask, to e: StageTaskEntity) {
        e.id = m.id; e.projectId = m.projectId; e.stage = m.stage.rawValue; e.title = m.title
        e.orderIndex = Int32(m.orderIndex); e.done = m.done; e.doneAt = m.doneAt
    }

    static func condition(from e: ConditionRecordEntity) -> ConditionRecord {
        ConditionRecord(id: e.id, projectId: e.projectId, phase: ConditionPhase(rawValue: e.phase) ?? .before, score: Int(e.score), notes: e.notes, photoPath: e.photoPath, recordedAt: e.recordedAt)
    }

    static func apply(_ m: ConditionRecord, to e: ConditionRecordEntity) {
        e.id = m.id; e.projectId = m.projectId; e.phase = m.phase.rawValue; e.score = Int32(m.score)
        e.notes = m.notes; e.photoPath = m.photoPath; e.recordedAt = m.recordedAt
    }
}
