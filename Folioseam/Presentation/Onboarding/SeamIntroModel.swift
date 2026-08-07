import Combine
import Foundation

/// Intro-only onboarding: it never creates a `BindingProject`. The first
/// project is created from the projects home screen instead; onboarding
/// merely records that the walkthrough was seen.
@MainActor
final class SeamIntroModel: ObservableObject {
    @Published var step = 0
    @Published var preferredStyle = "Case binding"
    @Published var tracksSections = true
    @Published var errorMessage: String?

    private let introSpine: SeamOnboardingPort

    init(introSpine: SeamOnboardingPort) {
        self.introSpine = introSpine
    }

    /// Advances to the next intro screen, or marks onboarding seen on the last screen.
    /// Returns `true` once the flag has been set and the caller should open the bench.
    func continueIntro() -> Bool {
        errorMessage = nil
        guard step >= 2 else {
            step += 1
            return false
        }
        introSpine.isCompleted = true
        return true
    }
}
