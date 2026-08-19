import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class ExportHubViewModel: ObservableObject {
    @Published var projects: [BindingProject] = []
    @Published var shareURL: URL?
    @Published var errorMessage: String?
    @Published var importError: String?
    @Published var importMessage: String?

    private let loadProjects: LoadProjectsUseCase
    private let exportProject: ExportProjectUseCase
    private let importProject: ImportProjectUseCase

    init(loadProjects: LoadProjectsUseCase, exportProject: ExportProjectUseCase, importProject: ImportProjectUseCase) {
        self.loadProjects = loadProjects
        self.exportProject = exportProject
        self.importProject = importProject
    }

    func refresh() async {
        projects = (try? await loadProjects()) ?? []
    }

    func importJSON(_ result: Result<[URL], Error>) async {
        do {
            guard let url = try result.get().first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            try await importProject(json: data)
            importMessage = "Project imported."
            await refresh()
        } catch {
            importError = "Could not import file. Check that it is a Folioseam export."
        }
    }

    func exportJSON(_ id: UUID) async {
        do {
            let data = try await exportProject.json(projectID: id)
            shareURL = try writeTemp(data: data, name: "folioseam-\(id.uuidString.prefix(8)).json")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportPDF(_ id: UUID) async {
        do {
            let data = try await exportProject.pdf(projectID: id)
            shareURL = try writeTemp(data: data, name: "folioseam-\(id.uuidString.prefix(8)).pdf")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func writeTemp(data: Data, name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
}

struct ExportHubView: View {
    @ObservedObject var viewModel: ExportHubViewModel
    @State private var showShare = false
    @State private var showImporter = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Export")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("JSON and PDF stay on device.")
                    .foregroundStyle(SeamPalette.ink.opacity(0.65))
                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
                Button("Import JSON") { showImporter = true }
                    .buttonStyle(.bordered)
                    .tint(SeamPalette.moss)
                if let importMessage = viewModel.importMessage {
                    Text(importMessage).foregroundStyle(SeamPalette.ink.opacity(0.65))
                }
                ForEach(viewModel.projects) { project in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(project.title).font(.headline)
                        HStack {
                            Button("JSON") { Task { await viewModel.exportJSON(project.id); showShare = viewModel.shareURL != nil } }
                            Button("PDF") { Task { await viewModel.exportPDF(project.id); showShare = viewModel.shareURL != nil } }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SeamPalette.moss)
                    }
                    .padding()
                    .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .binderyCanvas()
        .task { await viewModel.refresh() }
        .onAppear { Task { await viewModel.refresh() } }
        .sheet(isPresented: $showShare) {
            if let url = viewModel.shareURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            Task { await viewModel.importJSON(result) }
        }
        .alert(
            "Import failed",
            isPresented: Binding(
                get: { viewModel.importError != nil },
                set: { if !$0 { viewModel.importError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.importError ?? "")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("Export hub") {
    NavigationStack {
        ProjectPreviewHost { container, _ in
            ExportHubView(viewModel: container.makeExportViewModel())
        }
    }
}
