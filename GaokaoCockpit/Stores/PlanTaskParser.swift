import Foundation

struct ParsedPlanTask: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let source: String

    var sourceTitle: String {
        switch source {
        case PlanTaskParser.Source.top:
            return "Top"
        case PlanTaskParser.Source.baseline:
            return "保底"
        case PlanTaskParser.Source.bonus:
            return "加分"
        default:
            return source
        }
    }

    var category: String {
        switch source {
        case PlanTaskParser.Source.top:
            return "做题"
        case PlanTaskParser.Source.baseline:
            return "复盘"
        default:
            return "其他"
        }
    }
}

enum PlanTaskParser {
    enum Source {
        static let top = "top"
        static let baseline = "baseline"
        static let bonus = "bonus"
    }

    static func parseLines(from text: String) -> [String] {
        var seenTitles = Set<String>()
        var parsedLines: [String] = []

        for line in text.components(separatedBy: .newlines) {
            let title = cleanedLine(line)
            guard !title.isEmpty else {
                continue
            }

            let key = normalizedTitleKey(title)
            guard seenTitles.insert(key).inserted else {
                continue
            }

            parsedLines.append(title)
        }

        return parsedLines
    }

    static func parsePlanSections(
        top: String,
        baseline: String,
        bonus: String
    ) -> [ParsedPlanTask] {
        var seenTitles = Set<String>()
        var parsedTasks: [ParsedPlanTask] = []

        appendTasks(from: top, source: Source.top, seenTitles: &seenTitles, parsedTasks: &parsedTasks)
        appendTasks(from: baseline, source: Source.baseline, seenTitles: &seenTitles, parsedTasks: &parsedTasks)
        appendTasks(from: bonus, source: Source.bonus, seenTitles: &seenTitles, parsedTasks: &parsedTasks)

        return parsedTasks
    }

    static func normalizedTitleKey(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }

    private static func appendTasks(
        from text: String,
        source: String,
        seenTitles: inout Set<String>,
        parsedTasks: inout [ParsedPlanTask]
    ) {
        for title in parseLines(from: text) {
            let key = normalizedTitleKey(title)
            guard seenTitles.insert(key).inserted else {
                continue
            }

            parsedTasks.append(ParsedPlanTask(title: title, source: source))
        }
    }

    private static func cleanedLine(_ line: String) -> String {
        line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^\d+[\.、]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[-•]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\[\s?\]\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
