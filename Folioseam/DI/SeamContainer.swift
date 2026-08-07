import Foundation

/// Factory DI container for Folioseam.
@MainActor
final class SeamContainer {
    let store: SeamDataStore
    let projectRepository: BindingProjectRepository
    let sectionRepository: BookSectionRepository
    let materialRepository: MaterialLotRepository
    let stageRepository: StageTaskRepository
    let conditionRepository: ConditionRecordRepository
    let introSpine: SeamOnboardingPort
    let preferencesStore: PreferencesStore

    init(
        store: SeamDataStore,
        introSpine: SeamOnboardingPort = SeamFirstRunStore(),
        preferencesStore: PreferencesStore = SeamPreferenceStore()
    ) {
        self.store = store
        self.projectRepository = CoreDataBindingProjectRepository(store: store)
        self.sectionRepository = CoreDataBookSectionRepository(store: store)
        self.materialRepository = CoreDataMaterialLotRepository(store: store)
        self.stageRepository = CoreDataStageTaskRepository(store: store)
        self.conditionRepository = CoreDataConditionRecordRepository(store: store)
        self.introSpine = introSpine
        self.preferencesStore = preferencesStore
    }

    static func preview() -> SeamContainer {
        let store = try! SeamDataStore(location: .inMemory, name: "FolioseamPreview")
        return SeamContainer(
            store: store,
            introSpine: SeamFirstRunStore(
                defaults: UserDefaults(suiteName: "bindery.preview") ?? .standard
            )
        )
    }

    var loadProjects: LoadProjectsUseCase { LoadProjectsUseCase(repository: projectRepository) }
    var saveProject: SaveProjectUseCase { SaveProjectUseCase(repository: projectRepository) }
    var deleteProject: DeleteProjectUseCase { DeleteProjectUseCase(repository: projectRepository) }
    var loadProjectBundle: LoadProjectBundleUseCase {
        LoadProjectBundleUseCase(
            projects: projectRepository,
            sections: sectionRepository,
            materials: materialRepository,
            stages: stageRepository,
            conditions: conditionRepository
        )
    }
    var saveSection: SaveSectionUseCase { SaveSectionUseCase(repository: sectionRepository) }
    var deleteSection: DeleteSectionUseCase { DeleteSectionUseCase(repository: sectionRepository) }
    var saveMaterial: SaveMaterialUseCase { SaveMaterialUseCase(repository: materialRepository) }
    var deleteMaterial: DeleteMaterialUseCase { DeleteMaterialUseCase(repository: materialRepository) }
    var saveStage: SaveStageUseCase { SaveStageUseCase(repository: stageRepository) }
    var saveCondition: SaveConditionUseCase { SaveConditionUseCase(repository: conditionRepository) }
    var deleteCondition: DeleteConditionUseCase { DeleteConditionUseCase(repository: conditionRepository) }
    var computeProgress: ComputeProjectProgressUseCase { ComputeProjectProgressUseCase() }
    var exportProject: ExportProjectUseCase {
        ExportProjectUseCase(loadBundle: loadProjectBundle, computeProgress: computeProgress)
    }
    var importProject: ImportProjectUseCase {
        ImportProjectUseCase(
            projects: projectRepository,
            sections: sectionRepository,
            materials: materialRepository,
            stages: stageRepository,
            conditions: conditionRepository
        )
    }
    var loadBinderyStats: LoadBinderyStatsUseCase {
        LoadBinderyStatsUseCase(loadProjects: loadProjects, loadBundle: loadProjectBundle)
    }
    var resetData: ResetBinderyDataUseCase {
        ResetBinderyDataUseCase(
            projects: projectRepository,
            introSpine: introSpine
        )
    }

    func makeOnboardingViewModel() -> SeamIntroModel {
        SeamIntroModel(introSpine: introSpine)
    }

    func makeProjectsViewModel() -> ProjectsHomeViewModel {
        ProjectsHomeViewModel(loadProjects: loadProjects, deleteProject: deleteProject, loadBundle: loadProjectBundle, computeProgress: computeProgress)
    }

    func makeProjectDetailViewModel(projectID: UUID) -> ProjectDetailViewModel {
        ProjectDetailViewModel(
            projectID: projectID,
            loadBundle: loadProjectBundle,
            saveStage: saveStage,
            saveSection: saveSection,
            saveMaterial: saveMaterial,
            saveCondition: saveCondition,
            deleteSection: deleteSection,
            deleteMaterial: deleteMaterial,
            deleteCondition: deleteCondition,
            computeProgress: computeProgress
        )
    }

    func makeProjectEditorViewModel(projectID: UUID?) -> ProjectEditorViewModel {
        ProjectEditorViewModel(projectID: projectID, loadProjects: loadProjects, saveProject: saveProject, saveStage: saveStage)
    }

    func makeMaterialsViewModel() -> MaterialsHubViewModel {
        MaterialsHubViewModel(loadProjects: loadProjects, loadBundle: loadProjectBundle, saveMaterial: saveMaterial)
    }

    func makeExportViewModel() -> ExportHubViewModel {
        ExportHubViewModel(loadProjects: loadProjects, exportProject: exportProject, importProject: importProject)
    }

    func makeStatsViewModel() -> BinderyStatsViewModel {
        BinderyStatsViewModel(loadStats: loadBinderyStats)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(preferencesStore: preferencesStore, resetData: resetData)
    }
}
