import Foundation

enum ModelDefaults {
    enum StudyTaskStatus {
        static let pending = "pending"
        static let inProgress = "inProgress"
        static let done = "done"
        static let skipped = "skipped"
    }

    enum MistakeType {
        static let concept = "concept"
        static let method = "method"
        static let calculation = "calculation"
        static let reading = "reading"
        static let model = "model"
        static let expression = "expression"
        static let time = "time"
        static let other = "other"
    }

    enum ReviewStatus {
        static let new = "new"
        static let scheduled = "scheduled"
        static let reviewed = "reviewed"
        static let mastered = "mastered"
    }

    enum ResourceStatus {
        static let unread = "unread"
        static let inProgress = "inProgress"
        static let done = "done"
        static let archived = "archived"
    }
}
