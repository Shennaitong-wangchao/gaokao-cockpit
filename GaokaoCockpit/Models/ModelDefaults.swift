import Foundation

enum ModelDefaults {
    // New code should prefer the typed wrappers in ModelValueTypes.swift.
    // These string constants remain for older call sites and backup compatibility.
    enum StudyTaskStatus {
        static let pending = GaokaoCockpit.StudyTaskStatus.pending.storageValue
        static let inProgress = GaokaoCockpit.StudyTaskStatus.inProgress.storageValue
        static let done = GaokaoCockpit.StudyTaskStatus.done.storageValue
        static let skipped = GaokaoCockpit.StudyTaskStatus.skipped.storageValue
    }

    enum MistakeType {
        static let concept = GaokaoCockpit.MistakeType.concept.storageValue
        static let method = GaokaoCockpit.MistakeType.method.storageValue
        static let calculation = GaokaoCockpit.MistakeType.calculation.storageValue
        static let reading = GaokaoCockpit.MistakeType.reading.storageValue
        static let model = GaokaoCockpit.MistakeType.model.storageValue
        static let expression = GaokaoCockpit.MistakeType.expression.storageValue
        static let time = GaokaoCockpit.MistakeType.time.storageValue
        static let other = GaokaoCockpit.MistakeType.other.storageValue
    }

    enum ReviewStatus {
        static let new = GaokaoCockpit.ReviewStatus.new.storageValue
        static let scheduled = GaokaoCockpit.ReviewStatus.scheduled.storageValue
        static let reviewed = GaokaoCockpit.ReviewStatus.reviewed.storageValue
        static let mastered = GaokaoCockpit.ReviewStatus.mastered.storageValue
    }

    enum ResourceStatus {
        static let unread = GaokaoCockpit.ResourceStatus.unread.storageValue
        static let inProgress = GaokaoCockpit.ResourceStatus.inProgress.storageValue
        static let done = GaokaoCockpit.ResourceStatus.done.storageValue
        static let archived = GaokaoCockpit.ResourceStatus.archived.storageValue
    }
}
