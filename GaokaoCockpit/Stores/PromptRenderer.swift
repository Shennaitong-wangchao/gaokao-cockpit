import Foundation

enum PromptRenderer {
    static func render(templateText: String, values: [String: String]) -> String {
        let normalizedValues = values.reduce(into: [String: String]()) { result, pair in
            let key = pair.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else {
                return
            }

            result[key] = pair.value
        }

        let pattern = #"\{\{\s*([^}]+?)\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return templateText
        }

        let fullRange = NSRange(templateText.startIndex..<templateText.endIndex, in: templateText)
        let matches = regex.matches(in: templateText, range: fullRange)

        return matches.reversed().reduce(templateText) { renderedText, match in
            guard
                let placeholderRange = Range(match.range, in: renderedText),
                match.numberOfRanges > 1,
                let variableRange = Range(match.range(at: 1), in: templateText)
            else {
                return renderedText
            }

            let variableName = templateText[variableRange]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let replacement = normalizedValues[variableName]?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            var updatedText = renderedText
            updatedText.replaceSubrange(placeholderRange, with: replacement?.isEmpty == false ? replacement! : "未提供")
            return updatedText
        }
    }
}
