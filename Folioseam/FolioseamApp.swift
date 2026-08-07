import SwiftUI

/// Application entry point for Folioseam.
@main
struct FolioseamApp: App {

    private let container: SeamContainer?
    private let binderyFault: String?

    init() {
        do {
            container = SeamContainer(store: try SeamDataStore())
            binderyFault = nil
        } catch {
            container = nil
            binderyFault = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    RootView(container: container)
                } else {
                    SeamEmptyState(
                        title: "Unavailable",
                        detail: binderyFault ?? "The bindery store could not be opened."
                    )
                    .binderyCanvas()
                }
            }
        }
    }
}
