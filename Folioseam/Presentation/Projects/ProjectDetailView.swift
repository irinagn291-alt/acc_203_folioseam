import PhotosUI
import SwiftUI

struct ProjectDetailView: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var showPicker = false
    @State private var viewedPhoto: ConditionRecord?

    var body: some View {
        ScrollView {
            if let bundle = viewModel.bundle, let progress = viewModel.progress {
                VStack(alignment: .leading, spacing: 22) {
                    Text(bundle.project.title)
                        .font(.system(.title, design: .rounded).weight(.bold))
                    Text("\(bundle.project.bindingStyle) · \(bundle.project.clientOrOwner)")
                        .foregroundStyle(SeamPalette.ink.opacity(0.65))

                    ExplodedBindingCrossSection(progress: progress.projectProgress)
                        .frame(height: 160)

                    StitchTopologyProgress(sewnRatio: progress.sectionProgress)

                    metrics(progress)

                    BeforeAfterStrip(records: bundle.conditions) { viewedPhoto = $0 }

                    stages(bundle.stages)
                    sections(bundle.sections)
                    materials(bundle.materials)
                    conditions(bundle.conditions)
                }
                .padding(20)
            } else {
                ProgressView().frame(maxWidth: .infinity, minHeight: 240)
            }
        }
        .binderyCanvas()
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refresh() }
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .sheet(item: $viewedPhoto) { record in
            if let path = record.photoPath {
                ConditionPhotoViewer(
                    path: path,
                    caption: "\(record.phase.title) · condition \(record.score)"
                )
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                var path: String?
                if let data = try? await item.loadTransferable(type: Data.self) {
                    path = try? PhotoDisk.save(data: data, projectID: viewModel.projectID)
                }
                await viewModel.addCondition(photoPath: path)
                pickerItem = nil
            }
        }
        .sheet(isPresented: $viewModel.isPresentingSectionEditor) {
            if let editing = viewModel.editingSection {
                SectionEditorView(draft: editing) { saved in
                    Task { await viewModel.saveSectionEdit(saved) }
                }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingMaterialEditor) {
            if let editing = viewModel.editingMaterial {
                MaterialEditorView(draft: editing) { saved in
                    Task { await viewModel.saveMaterialEdit(saved) }
                }
            }
        }
    }

    private func metrics(_ progress: ProjectProgress) -> some View {
        HStack {
            metric("Progress", "\(Int(progress.projectProgress * 100))%")
            metric("Spend", String(format: "$%.2f", progress.materialSpend))
            metric("Δ condition", progress.conditionDelta.map { "\($0)" } ?? "—")
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.monospaced()).foregroundStyle(SeamPalette.ink.opacity(0.55))
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func stages(_ stages: [StageTask]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stages").font(.title3.weight(.semibold))
            ForEach(stages) { task in
                Button { Task { await viewModel.toggleStage(task) } } label: {
                    HStack {
                        Circle().fill(SeamPalette.stageColor(task.stage)).frame(width: 10, height: 10)
                        Text(task.title)
                        Spacer()
                        Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(SeamPalette.moss)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sections(_ sections: [BookSection]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sections").font(.title3.weight(.semibold))
            ForEach(sections) { section in
                Button { viewModel.beginEditSection(section) } label: {
                    HStack {
                        Text(section.name)
                        Spacer()
                        Text(section.sewn ? "Sewn" : "Open")
                            .font(.caption.monospaced())
                            .foregroundStyle(SeamPalette.moss)
                    }
                }
                .buttonStyle(.plain)
            }
            HStack {
                TextField("New section", text: $viewModel.newSectionName)
                    .textFieldStyle(.roundedBorder)
                Button("Add") { Task { await viewModel.addSection() } }
            }
        }
    }

    private func materials(_ lots: [MaterialLot]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Materials").font(.title3.weight(.semibold))
            MaterialSwatchStrip(lots: lots)
            ForEach(lots) { lot in
                Button { viewModel.beginEditMaterial(lot) } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(lot.name)
                            Text(lot.kind).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "$%.2f", Double(lot.costCents) / 100))
                            .font(.subheadline.monospaced())
                    }
                }
                .buttonStyle(.plain)
            }
            HStack {
                TextField("New lot", text: $viewModel.newMaterialName)
                    .textFieldStyle(.roundedBorder)
                Button("Add") { Task { await viewModel.addMaterial() } }
            }
        }
    }

    private func conditions(_ records: [ConditionRecord]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Condition").font(.title3.weight(.semibold))
            ForEach(records) { record in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(record.phase.title) · \(record.score)")
                        .font(.subheadline.weight(.semibold))
                    if !record.notes.isEmpty {
                        Text(record.notes).font(.footnote).foregroundStyle(.secondary)
                    }
                    if let path = record.photoPath {
                        Button { viewedPhoto = record } label: {
                            ConditionPhotoThumbnail(path: path)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(record.phase.title) photo, condition \(record.score). Double tap to enlarge.")
                    }
                    Text(record.recordedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2.monospaced())
                        .foregroundStyle(SeamPalette.ink.opacity(0.5))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.removeCondition(record) }
                    }
                }
            }
            Picker("Phase", selection: $viewModel.conditionPhase) {
                ForEach(ConditionPhase.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Stepper("Score \(viewModel.conditionScore)", value: $viewModel.conditionScore, in: 0...100)
            TextField("Notes", text: $viewModel.conditionNotes, axis: .vertical)
            if let denied = viewModel.photoDeniedMessage {
                Text(denied).font(.footnote).foregroundStyle(.orange)
            }
            HStack {
                Button("Save without photo") {
                    Task { await viewModel.addCondition(photoPath: nil) }
                }
                Button("Attach photo") {
                    Task {
                        if await viewModel.preparePhotoAttachment() {
                            showPicker = true
                        } else {
                            await viewModel.addCondition(photoPath: nil)
                        }
                    }
                }
            }
        }
    }
}

struct SectionEditorView: View {
    @State private var draft: BookSection
    @Environment(\.dismiss) private var dismiss
    private let onSave: (BookSection) -> Void

    init(draft: BookSection, onSave: @escaping (BookSection) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Section") {
                    TextField("Name", text: $draft.name)
                    Stepper("Pages: \(draft.pageCount)", value: $draft.pageCount, in: 1...500)
                    Stepper("Order: \(draft.orderIndex)", value: $draft.orderIndex, in: 0...200)
                    Toggle("Sewn", isOn: $draft.sewn)
                }
            }
            .navigationTitle(draft.name.isEmpty ? "New section" : "Edit section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

struct MaterialEditorView: View {
    @State private var draft: MaterialLot
    @State private var costDollars: Double
    @Environment(\.dismiss) private var dismiss
    private let onSave: (MaterialLot) -> Void

    init(draft: MaterialLot, onSave: @escaping (MaterialLot) -> Void) {
        _draft = State(initialValue: draft)
        _costDollars = State(initialValue: Double(draft.costCents) / 100)
        self.onSave = onSave
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Material") {
                    TextField("Name", text: $draft.name)
                    TextField("Kind", text: $draft.kind)
                    HStack {
                        TextField("Quantity", value: $draft.quantity, format: .number)
                            .keyboardType(.decimalPad)
                        TextField("Unit", text: $draft.unit)
                            .frame(maxWidth: 80)
                    }
                    TextField("Cost", value: $costDollars, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
                Section("Notes") {
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(draft.name.isEmpty ? "New material" : "Edit material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var normalized = draft
                        normalized.costCents = Int((costDollars * 100).rounded())
                        onSave(normalized)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

enum PhotoDisk {
    static func save(data: Data, projectID: UUID) throws -> String {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ConditionPhotos", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(projectID.uuidString)-\(UUID().uuidString).jpg")
        try data.write(to: url, options: .atomic)
        return url.path
    }
}

#Preview("Project detail") {
    NavigationStack {
        ProjectPreviewHost { container, projectID in
            ProjectDetailView(viewModel: container.makeProjectDetailViewModel(projectID: projectID))
        }
    }
}
