import PhotosUI
import SwiftData
import SwiftUI
import UIKit

enum MistakeEditorMode: Identifiable {
    case add
    case edit(MistakeRecord)

    var id: String {
        switch self {
        case .add:
            return "add-mistake"
        case .edit(let mistake):
            return mistake.id.uuidString
        }
    }

    var title: String {
        switch self {
        case .add:
            return "新增错题手术"
        case .edit:
            return "编辑错题手术"
        }
    }
}

struct MistakeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: MistakeEditorMode
    let onChanged: (String) -> Void
    private let draftMistakeID: UUID
    private let originalQuestionImagePath: String

    @State private var subject: String
    @State private var chapter: String
    @State private var source: String
    @State private var questionText: String
    @State private var questionImagePath: String
    @State private var mySolution: String
    @State private var correctSolution: String
    @State private var mistakeType: String
    @State private var rootCause: String
    @State private var questionSignal: String
    @State private var correctModel: String
    @State private var variantTask: String
    @State private var hasNextReminder: Bool
    @State private var nextReminder: Date
    @State private var reviewStatus: String
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCameraPicker = false
    @State private var showingDeleteImageConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var pendingImagePathsToDelete: Set<String> = []
    @State private var didCommitImageChanges = false

    init(mode: MistakeEditorMode, onChanged: @escaping (String) -> Void) {
        self.mode = mode
        self.onChanged = onChanged

        let initialMistakeID: UUID
        let initialImagePath: String

        switch mode {
        case .add:
            initialMistakeID = UUID()
            initialImagePath = ""
            _subject = State(initialValue: "数学")
            _chapter = State(initialValue: "")
            _source = State(initialValue: "")
            _questionText = State(initialValue: "")
            _questionImagePath = State(initialValue: "")
            _mySolution = State(initialValue: "")
            _correctSolution = State(initialValue: "")
            _mistakeType = State(initialValue: ModelDefaults.MistakeType.model)
            _rootCause = State(initialValue: "")
            _questionSignal = State(initialValue: "")
            _correctModel = State(initialValue: "")
            _variantTask = State(initialValue: "")
            _hasNextReminder = State(initialValue: false)
            _nextReminder = State(initialValue: Date())
            _reviewStatus = State(initialValue: ModelDefaults.ReviewStatus.new)

        case .edit(let mistake):
            initialMistakeID = mistake.id
            initialImagePath = mistake.questionImagePath.trimmingCharacters(in: .whitespacesAndNewlines)
            _subject = State(initialValue: mistake.subject.isEmpty ? "其他" : mistake.subject)
            _chapter = State(initialValue: mistake.chapter)
            _source = State(initialValue: mistake.source)
            _questionText = State(initialValue: mistake.questionText)
            _questionImagePath = State(initialValue: mistake.questionImagePath)
            _mySolution = State(initialValue: mistake.mySolution)
            _correctSolution = State(initialValue: mistake.correctSolution)
            _mistakeType = State(initialValue: mistake.mistakeType.isEmpty ? ModelDefaults.MistakeType.model : mistake.mistakeType)
            _rootCause = State(initialValue: mistake.rootCause)
            _questionSignal = State(initialValue: mistake.questionSignal)
            _correctModel = State(initialValue: mistake.correctModel)
            _variantTask = State(initialValue: mistake.variantTask)
            _hasNextReminder = State(initialValue: mistake.nextReminder != nil)
            _nextReminder = State(initialValue: mistake.nextReminder ?? Date())
            _reviewStatus = State(initialValue: mistake.reviewStatus.isEmpty ? ModelDefaults.ReviewStatus.new : mistake.reviewStatus)
        }

        self.draftMistakeID = initialMistakeID
        self.originalQuestionImagePath = initialImagePath
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基础信息") {
                    Picker("科目", selection: $subject) {
                        ForEach(pickerOptions(defaults: MistakeFormOptions.subjects, current: subject), id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }

                    TextField("章节/专题", text: $chapter)
                        .accessibilityLabel("章节专题")

                    TextField("来源", text: $source)
                        .accessibilityLabel("来源")
                }

                Section("题目") {
                    TextEditor(text: $questionText)
                        .frame(minHeight: 100)
                        .accessibilityLabel("题目文字")
                }

                Section("题目图片") {
                    VStack(alignment: .leading, spacing: 12) {
                        if let image = currentQuestionImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityLabel("错题题图预览")
                        } else if hasQuestionImagePath {
                            ContentUnavailableView {
                                Label("题图暂时无法读取", systemImage: "photo.badge.exclamationmark")
                            } description: {
                                Text("可以重新选择一张图片，或删除当前图片记录。")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else {
                            Text("还没有题图。可以从相册选择或直接拍照。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Label(hasQuestionImagePath ? "更换图片" : "从相册选择", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                showingCameraPicker = true
                            } label: {
                                Label("拍照上传", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(!isCameraAvailable)
                        }

                        if !isCameraAvailable {
                            Text("当前设备没有可用相机。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if hasQuestionImagePath {
                            Button(role: .destructive) {
                                showingDeleteImageConfirmation = true
                            } label: {
                                Label("删除图片", systemImage: "trash")
                            }
                        }
                    }
                }

                Section("解法对照") {
                    TextEditor(text: $mySolution)
                        .frame(minHeight: 90)
                        .accessibilityLabel("我的原解")

                    TextEditor(text: $correctSolution)
                        .frame(minHeight: 90)
                        .accessibilityLabel("正确解法")
                }

                Section("手术拆解") {
                    Picker("错误类型", selection: $mistakeType) {
                        ForEach(mistakeTypeOptions) { option in
                            Text(option.title).tag(option.type)
                        }
                    }

                    TextEditor(text: $rootCause)
                        .frame(minHeight: 90)
                        .accessibilityLabel("根因")

                    TextEditor(text: $questionSignal)
                        .frame(minHeight: 80)
                        .accessibilityLabel("题目信号")

                    TextEditor(text: $correctModel)
                        .frame(minHeight: 90)
                        .accessibilityLabel("正确模型")

                    TextEditor(text: $variantTask)
                        .frame(minHeight: 80)
                        .accessibilityLabel("变式任务")
                }

                Section("复习状态") {
                    Picker("状态", selection: $reviewStatus) {
                        ForEach(reviewStatusOptions) { option in
                            Text(option.title).tag(option.status)
                        }
                    }

                    Toggle("设置下次提醒时间", isOn: $hasNextReminder)

                    if hasNextReminder {
                        DatePicker(
                            "下次提醒时间",
                            selection: $nextReminder,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if case .edit = mode {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("删除错题手术", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        cancelEditing()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveMistake()
                    }
                    .disabled(clean(subject).isEmpty)
                }
            }
            .confirmationDialog(
                "确认删除当前题图？",
                isPresented: $showingDeleteImageConfirmation,
                titleVisibility: .visible
            ) {
                Button("删除图片", role: .destructive) {
                    deleteCurrentImage()
                }

                Button("取消", role: .cancel) {}
            } message: {
                Text("保存错题后，图片记录会从这条错题中移除。")
            }
            .confirmationDialog(
                "确认删除这条错题手术？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("删除错题手术", role: .destructive) {
                    deleteMistake()
                }

                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后无法恢复。")
            }
            .sheet(isPresented: $showingCameraPicker) {
                CameraImagePicker { image in
                    savePickedImage(image)
                }
            }
            .onChange(of: selectedPhotoItem) {
                guard let selectedPhotoItem else {
                    return
                }

                Task {
                    await loadSelectedPhoto(selectedPhotoItem)
                }
            }
            .onDisappear {
                cleanupUncommittedDraftImage()
            }
        }
    }

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var hasQuestionImagePath: Bool {
        !clean(questionImagePath).isEmpty
    }

    private var currentQuestionImage: UIImage? {
        MistakeImageStore.loadImage(path: questionImagePath)
    }

    @MainActor
    private func loadSelectedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "读取相册图片失败。"
                selectedPhotoItem = nil
                return
            }

            guard let image = UIImage(data: data) else {
                errorMessage = "相册图片格式无法读取。"
                selectedPhotoItem = nil
                return
            }

            savePickedImage(image)
            selectedPhotoItem = nil
        } catch {
            errorMessage = "读取相册图片失败：\(error.localizedDescription)"
            selectedPhotoItem = nil
        }
    }

    private func savePickedImage(_ image: UIImage) {
        do {
            let previousPath = clean(questionImagePath)
            let savedPath = try MistakeImageStore.saveImage(image, mistakeId: draftMistakeID)
            stageReplacementImage(previousPath: previousPath, newPath: savedPath)
            questionImagePath = savedPath
            errorMessage = nil
        } catch {
            errorMessage = "保存图片失败：\(error.localizedDescription)"
        }
    }

    private func stageReplacementImage(previousPath: String, newPath: String) {
        guard !previousPath.isEmpty, previousPath != newPath else {
            return
        }

        if previousPath == originalQuestionImagePath {
            pendingImagePathsToDelete.insert(previousPath)
        } else {
            try? MistakeImageStore.deleteImage(path: previousPath)
        }
    }

    private func deleteCurrentImage() {
        let currentPath = clean(questionImagePath)
        guard !currentPath.isEmpty else {
            return
        }

        if currentPath == originalQuestionImagePath {
            pendingImagePathsToDelete.insert(currentPath)
            questionImagePath = ""
            errorMessage = nil
            return
        }

        do {
            try MistakeImageStore.deleteImage(path: currentPath)
            questionImagePath = ""
            errorMessage = nil
        } catch {
            errorMessage = "删除图片失败：\(error.localizedDescription)"
        }
    }

    private func cancelEditing() {
        cleanupUncommittedDraftImage()
        dismiss()
    }

    private func cleanupUncommittedDraftImage() {
        guard !didCommitImageChanges else {
            return
        }

        let currentPath = clean(questionImagePath)
        guard !currentPath.isEmpty, currentPath != originalQuestionImagePath else {
            return
        }

        try? MistakeImageStore.deleteImage(path: currentPath)
    }

    private func deletePendingImagePathsAfterSave() throws {
        let savedPath = clean(questionImagePath)
        let paths = pendingImagePathsToDelete.filter { !$0.isEmpty && $0 != savedPath }

        for path in paths {
            try MistakeImageStore.deleteImage(path: path)
        }

        pendingImagePathsToDelete.removeAll()
    }

    private var mistakeTypeOptions: [MistakeTypeOption] {
        let options = MistakeTypeOption.all
        guard !mistakeType.isEmpty, !options.contains(where: { $0.type == mistakeType }) else {
            return options
        }

        return options + [MistakeTypeOption(type: mistakeType, title: mistakeType, systemImage: "questionmark.circle")]
    }

    private var reviewStatusOptions: [ReviewStatusOption] {
        let options = ReviewStatusOption.all
        guard !reviewStatus.isEmpty, !options.contains(where: { $0.status == reviewStatus }) else {
            return options
        }

        return options + [ReviewStatusOption(status: reviewStatus, title: reviewStatus, systemImage: "questionmark.circle")]
    }

    private func saveMistake() {
        let cleanSubject = clean(subject)
        guard !cleanSubject.isEmpty else {
            errorMessage = "请先选择或填写科目。"
            return
        }

        let reminder = hasNextReminder ? nextReminder : nil

        do {
            switch mode {
            case .add:
                _ = try MistakeRecordStore.createMistake(
                    id: draftMistakeID,
                    subject: cleanSubject,
                    chapter: clean(chapter),
                    source: clean(source),
                    questionText: clean(questionText),
                    questionImagePath: clean(questionImagePath),
                    mySolution: clean(mySolution),
                    correctSolution: clean(correctSolution),
                    mistakeType: mistakeType,
                    rootCause: clean(rootCause),
                    questionSignal: clean(questionSignal),
                    correctModel: clean(correctModel),
                    variantTask: clean(variantTask),
                    nextReminder: reminder,
                    reviewStatus: reviewStatus,
                    in: modelContext
                )
                try deletePendingImagePathsAfterSave()
                didCommitImageChanges = true
                onChanged("已新增错题手术。")

            case .edit(let mistake):
                mistake.subject = cleanSubject
                mistake.chapter = clean(chapter)
                mistake.source = clean(source)
                mistake.questionText = clean(questionText)
                mistake.questionImagePath = clean(questionImagePath)
                mistake.mySolution = clean(mySolution)
                mistake.correctSolution = clean(correctSolution)
                mistake.mistakeType = mistakeType
                mistake.rootCause = clean(rootCause)
                mistake.questionSignal = clean(questionSignal)
                mistake.correctModel = clean(correctModel)
                mistake.variantTask = clean(variantTask)
                mistake.nextReminder = reminder
                mistake.reviewStatus = reviewStatus
                MistakeRecordStore.updateMistakeTimestamp(mistake)
                try modelContext.save()
                try deletePendingImagePathsAfterSave()
                didCommitImageChanges = true
                onChanged("已保存错题手术。")
            }

            dismiss()
        } catch {
            errorMessage = "保存错题失败：\(error.localizedDescription)"
        }
    }

    private func deleteMistake() {
        guard case .edit(let mistake) = mode else {
            return
        }

        do {
            let imagePathsToDelete = Set([
                clean(mistake.questionImagePath),
                clean(questionImagePath)
            ]).filter { !$0.isEmpty }
            try MistakeRecordStore.deleteMistake(mistake, in: modelContext)
            for path in imagePathsToDelete {
                try? MistakeImageStore.deleteImage(path: path)
            }
            didCommitImageChanges = true
            onChanged("已删除错题手术。")
            dismiss()
        } catch {
            errorMessage = "删除错题失败：\(error.localizedDescription)"
        }
    }

    private func pickerOptions(defaults: [String], current: String) -> [String] {
        let cleanCurrent = clean(current)
        guard !cleanCurrent.isEmpty, !defaults.contains(cleanCurrent) else {
            return defaults
        }

        return defaults + [cleanCurrent]
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum MistakeFormOptions {
    static let subjects = ["数学", "语文", "英语", "物理", "化学", "生物", "其他"]
}

struct MistakeTypeOption: Identifiable {
    let type: String
    let title: String
    let systemImage: String

    var id: String { type }

    static let all: [MistakeTypeOption] = [
        MistakeTypeOption(type: ModelDefaults.MistakeType.concept, title: "概念", systemImage: "book.closed"),
        MistakeTypeOption(type: ModelDefaults.MistakeType.method, title: "方法", systemImage: "point.3.connected.trianglepath.dotted"),
        MistakeTypeOption(type: ModelDefaults.MistakeType.calculation, title: "计算", systemImage: "function"),
        MistakeTypeOption(type: ModelDefaults.MistakeType.reading, title: "审题", systemImage: "text.magnifyingglass"),
        MistakeTypeOption(type: ModelDefaults.MistakeType.model, title: "模型", systemImage: "cube.transparent"),
        MistakeTypeOption(type: ModelDefaults.MistakeType.expression, title: "表达", systemImage: "text.quote"),
        MistakeTypeOption(type: ModelDefaults.MistakeType.time, title: "时间", systemImage: "clock"),
        MistakeTypeOption(type: ModelDefaults.MistakeType.other, title: "其他", systemImage: "ellipsis.circle")
    ]

    static func title(for type: String) -> String {
        all.first { $0.type == type }?.title ?? (type.isEmpty ? "未分类" : type)
    }

    static func systemImage(for type: String) -> String {
        all.first { $0.type == type }?.systemImage ?? "questionmark.circle"
    }
}

struct ReviewStatusOption: Identifiable {
    let status: String
    let title: String
    let systemImage: String

    var id: String { status }

    var tint: Color {
        switch status {
        case ModelDefaults.ReviewStatus.scheduled:
            return .blue
        case ModelDefaults.ReviewStatus.reviewed:
            return .green
        case ModelDefaults.ReviewStatus.mastered:
            return .purple
        default:
            return .orange
        }
    }

    static let all: [ReviewStatusOption] = [
        ReviewStatusOption(status: ModelDefaults.ReviewStatus.new, title: "新错题", systemImage: "sparkle"),
        ReviewStatusOption(status: ModelDefaults.ReviewStatus.scheduled, title: "待复习", systemImage: "calendar.badge.clock"),
        ReviewStatusOption(status: ModelDefaults.ReviewStatus.reviewed, title: "已复习", systemImage: "checkmark.circle"),
        ReviewStatusOption(status: ModelDefaults.ReviewStatus.mastered, title: "已掌握", systemImage: "graduationcap")
    ]

    static func title(for status: String) -> String {
        all.first { $0.status == status }?.title ?? (status.isEmpty ? "未知状态" : status)
    }

    static func systemImage(for status: String) -> String {
        all.first { $0.status == status }?.systemImage ?? "questionmark.circle"
    }

    static func tint(for status: String) -> Color {
        all.first { $0.status == status }?.tint ?? .secondary
    }
}

#Preview("新增错题手术") {
    let container = try! AppModelContainerFactory.make(inMemory: true)

    return MistakeEditorView(mode: .add) { _ in }
        .modelContainer(container)
}
