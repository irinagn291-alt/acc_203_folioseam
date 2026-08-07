import CoreData
import Foundation

@objc(BindingProjectEntity)
final class BindingProjectEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var clientOrOwner: String
    @NSManaged var bindingStyle: String
    @NSManaged var openedAt: Date
    @NSManaged var status: String
    @NSManaged var notes: String
}

@objc(BookSectionEntity)
final class BookSectionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var projectId: UUID
    @NSManaged var name: String
    @NSManaged var pageCount: Int32
    @NSManaged var orderIndex: Int32
    @NSManaged var sewn: Bool
}

@objc(MaterialLotEntity)
final class MaterialLotEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var projectId: UUID
    @NSManaged var kind: String
    @NSManaged var name: String
    @NSManaged var quantity: Double
    @NSManaged var unit: String
    @NSManaged var costCents: Int32
    @NSManaged var notes: String
}

@objc(StageTaskEntity)
final class StageTaskEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var projectId: UUID
    @NSManaged var stage: String
    @NSManaged var title: String
    @NSManaged var orderIndex: Int32
    @NSManaged var done: Bool
    @NSManaged var doneAt: Date?
}

@objc(ConditionRecordEntity)
final class ConditionRecordEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var projectId: UUID
    @NSManaged var phase: String
    @NSManaged var score: Int32
    @NSManaged var notes: String
    @NSManaged var photoPath: String?
    @NSManaged var recordedAt: Date
}

enum SeamEntityName {
    static let project = "BindingProjectEntity"
    static let section = "BookSectionEntity"
    static let material = "MaterialLotEntity"
    static let stage = "StageTaskEntity"
    static let condition = "ConditionRecordEntity"
}
