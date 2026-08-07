import CoreData
import Foundation

/// The schema now lives in `FolioseamBindery.xcdatamodeld`; this type only
/// wires up the container and a dedicated writer context.
final class SeamDataStore: @unchecked Sendable {
    enum Location: Sendable { case onDisk, inMemory }

    private let container: NSPersistentContainer
    private let writer: NSManagedObjectContext

    init(location: Location = .onDisk, name: String = "FolioseamBindery") throws {
        let built = NSPersistentContainer(name: name)

        if location == .inMemory {
            let ephemeral = NSPersistentStoreDescription()
            ephemeral.type = NSInMemoryStoreType
            ephemeral.shouldAddStoreAsynchronously = false
            built.persistentStoreDescriptions = [ephemeral]
        } else {
            built.persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = false }
        }

        var openError: Error?
        built.loadPersistentStores { _, error in
            if let error { openError = error }
        }
        if let openError {
            throw SeamError.storeFailure(openError.localizedDescription)
        }

        writer = built.newBackgroundContext()
        writer.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        writer.automaticallyMergesChangesFromParent = true
        container = built
    }

    func withContext<T: Sendable>(
        _ body: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = writer
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do { continuation.resume(returning: try body(context)) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }
}
