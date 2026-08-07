import CoreData
import Foundation

enum SeamRepo {
    static func commit(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch {
            context.rollback()
            throw SeamError.storeFailure(error.localizedDescription)
        }
    }
}

final class CoreDataBindingProjectRepository: BindingProjectRepository {
    private let store: SeamDataStore
    init(store: SeamDataStore) { self.store = store }

    func fetchAll() async throws -> [BindingProject] {
        try await store.withContext { context in
            let r = NSFetchRequest<BindingProjectEntity>(entityName: SeamEntityName.project)
            r.sortDescriptors = [NSSortDescriptor(key: "openedAt", ascending: false)]
            return try context.fetch(r).map(SeamMapping.project(from:))
        }
    }

    func fetch(id: UUID) async throws -> BindingProject? {
        try await store.withContext { context in
            try Self.row(id: id, in: context).map(SeamMapping.project(from:))
        }
    }

    func save(_ project: BindingProject) async throws {
        try await store.withContext { context in
            let e = try Self.row(id: project.id, in: context) ?? BindingProjectEntity(context: context)
            SeamMapping.apply(project, to: e)
            try SeamRepo.commit(context)
        }
    }

    func delete(id: UUID) async throws {
        try await store.withContext { context in
            if let e = try Self.row(id: id, in: context) {
                // cascade children
                for name in [SeamEntityName.section, SeamEntityName.material, SeamEntityName.stage, SeamEntityName.condition] {
                    let r = NSFetchRequest<NSManagedObject>(entityName: name)
                    r.predicate = NSPredicate(format: "projectId == %@", id as CVarArg)
                    for child in try context.fetch(r) { context.delete(child) }
                }
                context.delete(e)
                try SeamRepo.commit(context)
            }
        }
    }

    func count() async throws -> Int {
        try await store.withContext { context in
            try context.count(for: NSFetchRequest<BindingProjectEntity>(entityName: SeamEntityName.project))
        }
    }

    private static func row(id: UUID, in context: NSManagedObjectContext) throws -> BindingProjectEntity? {
        let r = NSFetchRequest<BindingProjectEntity>(entityName: SeamEntityName.project)
        r.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        r.fetchLimit = 1
        return try context.fetch(r).first
    }
}

final class CoreDataBookSectionRepository: BookSectionRepository {
    private let store: SeamDataStore
    init(store: SeamDataStore) { self.store = store }

    func fetch(projectId: UUID) async throws -> [BookSection] {
        try await store.withContext { context in
            let r = NSFetchRequest<BookSectionEntity>(entityName: SeamEntityName.section)
            r.predicate = NSPredicate(format: "projectId == %@", projectId as CVarArg)
            r.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
            return try context.fetch(r).map(SeamMapping.section(from:))
        }
    }

    func save(_ section: BookSection) async throws {
        try await store.withContext { context in
            let e = try Self.row(id: section.id, in: context) ?? BookSectionEntity(context: context)
            SeamMapping.apply(section, to: e)
            try SeamRepo.commit(context)
        }
    }

    func delete(id: UUID) async throws {
        try await store.withContext { context in
            if let e = try Self.row(id: id, in: context) { context.delete(e); try SeamRepo.commit(context) }
        }
    }

    private static func row(id: UUID, in context: NSManagedObjectContext) throws -> BookSectionEntity? {
        let r = NSFetchRequest<BookSectionEntity>(entityName: SeamEntityName.section)
        r.predicate = NSPredicate(format: "id == %@", id as CVarArg); r.fetchLimit = 1
        return try context.fetch(r).first
    }
}

final class CoreDataMaterialLotRepository: MaterialLotRepository {
    private let store: SeamDataStore
    init(store: SeamDataStore) { self.store = store }

    func fetch(projectId: UUID) async throws -> [MaterialLot] {
        try await store.withContext { context in
            let r = NSFetchRequest<MaterialLotEntity>(entityName: SeamEntityName.material)
            r.predicate = NSPredicate(format: "projectId == %@", projectId as CVarArg)
            r.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(r).map(SeamMapping.material(from:))
        }
    }

    func fetchAll() async throws -> [MaterialLot] {
        try await store.withContext { context in
            let r = NSFetchRequest<MaterialLotEntity>(entityName: SeamEntityName.material)
            r.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(r).map(SeamMapping.material(from:))
        }
    }

    func save(_ lot: MaterialLot) async throws {
        try await store.withContext { context in
            let e = try Self.row(id: lot.id, in: context) ?? MaterialLotEntity(context: context)
            SeamMapping.apply(lot, to: e)
            try SeamRepo.commit(context)
        }
    }

    func delete(id: UUID) async throws {
        try await store.withContext { context in
            if let e = try Self.row(id: id, in: context) { context.delete(e); try SeamRepo.commit(context) }
        }
    }

    private static func row(id: UUID, in context: NSManagedObjectContext) throws -> MaterialLotEntity? {
        let r = NSFetchRequest<MaterialLotEntity>(entityName: SeamEntityName.material)
        r.predicate = NSPredicate(format: "id == %@", id as CVarArg); r.fetchLimit = 1
        return try context.fetch(r).first
    }
}

final class CoreDataStageTaskRepository: StageTaskRepository {
    private let store: SeamDataStore
    init(store: SeamDataStore) { self.store = store }

    func fetch(projectId: UUID) async throws -> [StageTask] {
        try await store.withContext { context in
            let r = NSFetchRequest<StageTaskEntity>(entityName: SeamEntityName.stage)
            r.predicate = NSPredicate(format: "projectId == %@", projectId as CVarArg)
            r.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
            return try context.fetch(r).map(SeamMapping.stage(from:))
        }
    }

    func save(_ task: StageTask) async throws {
        try await store.withContext { context in
            let e = try Self.row(id: task.id, in: context) ?? StageTaskEntity(context: context)
            SeamMapping.apply(task, to: e)
            try SeamRepo.commit(context)
        }
    }

    func delete(id: UUID) async throws {
        try await store.withContext { context in
            if let e = try Self.row(id: id, in: context) { context.delete(e); try SeamRepo.commit(context) }
        }
    }

    private static func row(id: UUID, in context: NSManagedObjectContext) throws -> StageTaskEntity? {
        let r = NSFetchRequest<StageTaskEntity>(entityName: SeamEntityName.stage)
        r.predicate = NSPredicate(format: "id == %@", id as CVarArg); r.fetchLimit = 1
        return try context.fetch(r).first
    }
}

final class CoreDataConditionRecordRepository: ConditionRecordRepository {
    private let store: SeamDataStore
    init(store: SeamDataStore) { self.store = store }

    func fetch(projectId: UUID) async throws -> [ConditionRecord] {
        try await store.withContext { context in
            let r = NSFetchRequest<ConditionRecordEntity>(entityName: SeamEntityName.condition)
            r.predicate = NSPredicate(format: "projectId == %@", projectId as CVarArg)
            r.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: true)]
            return try context.fetch(r).map(SeamMapping.condition(from:))
        }
    }

    func save(_ record: ConditionRecord) async throws {
        try await store.withContext { context in
            let e = try Self.row(id: record.id, in: context) ?? ConditionRecordEntity(context: context)
            SeamMapping.apply(record, to: e)
            try SeamRepo.commit(context)
        }
    }

    func delete(id: UUID) async throws {
        try await store.withContext { context in
            if let e = try Self.row(id: id, in: context) { context.delete(e); try SeamRepo.commit(context) }
        }
    }

    private static func row(id: UUID, in context: NSManagedObjectContext) throws -> ConditionRecordEntity? {
        let r = NSFetchRequest<ConditionRecordEntity>(entityName: SeamEntityName.condition)
        r.predicate = NSPredicate(format: "id == %@", id as CVarArg); r.fetchLimit = 1
        return try context.fetch(r).first
    }
}

final class SeamFirstRunStore: SeamOnboardingPort, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "folioseam.onboarding.completed"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var isCompleted: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}

final class SeamPreferenceStore: PreferencesStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let costsKey = "folioseam.prefs.showCosts"
    private let styleKey = "folioseam.prefs.style"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var preferences: AppPreferences {
        get {
            AppPreferences(
                showMaterialCosts: defaults.object(forKey: costsKey) as? Bool ?? true,
                defaultBindingStyle: defaults.string(forKey: styleKey) ?? "Case binding"
            )
        }
        set {
            defaults.set(newValue.showMaterialCosts, forKey: costsKey)
            defaults.set(newValue.defaultBindingStyle, forKey: styleKey)
        }
    }
}
