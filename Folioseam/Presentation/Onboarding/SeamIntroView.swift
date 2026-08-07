import SwiftUI

struct SeamIntroView: View {
    @ObservedObject var viewModel: SeamIntroModel
    var onFinished: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $viewModel.step) {
                stepCard(
                    image: "LayerHero",
                    title: "Bind, restore, finish books",
                    subtitle: "Folioseam tracks restoration work as an exploded book block, not a reading journal."
                ) {
                    Text("Your first project is created from the bench once you're inside.")
                        .foregroundStyle(SeamPalette.ink.opacity(0.7))
                }
                .tag(0)

                stepCard(
                    image: "StitchHero",
                    title: "Pick a default style",
                    subtitle: "New projects start with this binding style. You can change it per project later."
                ) {
                    Picker("Default style", selection: $viewModel.preferredStyle) {
                        Text("Case binding").tag("Case binding")
                        Text("Coptic stitch").tag("Coptic stitch")
                        Text("Long stitch").tag("Long stitch")
                        Text("Perfect binding").tag("Perfect binding")
                    }
                    .pickerStyle(.menu)
                }
                .tag(1)

                stepCard(
                    image: "SwatchHero",
                    title: "Track sections and materials",
                    subtitle: "Keep book sections and material lots alongside each project's stage progress."
                ) {
                    Toggle("Track book sections", isOn: $viewModel.tracksSections)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            if let error = viewModel.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red).padding(.horizontal)
            }

            Button {
                if viewModel.continueIntro() { onFinished() }
            } label: {
                Text(viewModel.step == 2 ? "Enter bindery" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SeamPalette.moss)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding()
        }
        .binderyCanvas()
    }

    @ViewBuilder
    private func stepCard<Content: View>(
        image: String,
        title: String,
        subtitle: String,
        @ViewBuilder fields: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
                Text("Folioseam")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(SeamPalette.ink)
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(SeamPalette.ink.opacity(0.7))
                fields()
            }
            .padding(24)
        }
    }
}

#Preview("Onboarding") {
    SeamIntroView(viewModel: SeamContainer.preview().makeOnboardingViewModel(), onFinished: {})
}
