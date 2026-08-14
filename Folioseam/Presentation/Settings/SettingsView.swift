import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var preferences: AppPreferences
    @Published var didReset = false

    private let preferencesStore: PreferencesStore
    private let resetData: ResetBinderyDataUseCase

    init(preferencesStore: PreferencesStore, resetData: ResetBinderyDataUseCase) {
        self.preferencesStore = preferencesStore
        self.resetData = resetData
        self.preferences = preferencesStore.preferences
    }

    func persist() {
        preferencesStore.preferences = preferences
    }

    func reset() async {
        try? await resetData()
        didReset = true
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    var onResetOnboarding: () -> Void

    var body: some View {
        Form {
            Section("Bench") {
                Toggle("Show material costs", isOn: $viewModel.preferences.showMaterialCosts)
                    .onChange(of: viewModel.preferences) { _, _ in viewModel.persist() }
                TextField("Default binding style", text: $viewModel.preferences.defaultBindingStyle)
                    .onChange(of: viewModel.preferences.defaultBindingStyle) { _, _ in viewModel.persist() }
            }
            Section("Data") {
                Button("Reset all bindery data", role: .destructive) {
                    Task {
                        await viewModel.reset()
                        onResetOnboarding()
                    }
                }
            }
            Section("Support") {
                Link("Website", destination: GateConfig.siteURL)
                Link("Contact Us", destination: GateConfig.contactURL)
            }
            Section("About") {
                LabeledContent("App", value: "Folioseam")
                LabeledContent("Focus", value: "Bookbinding desk")
            }
        }
    }
}

#Preview("Settings") {
    SettingsView(viewModel: SeamContainer.preview().makeSettingsViewModel(), onResetOnboarding: {})
}
