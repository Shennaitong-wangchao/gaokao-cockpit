import Foundation
import SwiftUI
import UIKit

struct MistakeRow: View {
    let mistake: MistakeRecord
    let onTap: () -> Void
    let onPreviewImage: (String) -> Void
    let onGeneratePrompt: () -> Void
    let onChangeStatus: (ReviewStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MistakeQuestionThumbnail(
                    path: mistake.questionImagePath,
                    onTap: onPreviewImage
                )

                Button {
                    onTap()
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            MistakeTag(text: mistake.surgerySubjectText)
                            MistakeTag(text: mistake.chapter.isEmpty ? "未设章节" : mistake.chapter)
                            Spacer(minLength: 8)
                            MistakeStatusBadge(status: mistake.reviewStatus)
                        }

                        Text(mistake.questionPreviewText)
                            .font(.headline)
                            .foregroundStyle(mistake.questionText.isEmpty ? .secondary : .primary)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Label(MistakeTypeOption.title(for: mistake.mistakeType), systemImage: MistakeTypeOption.systemImage(for: mistake.mistakeType))
                            Text(mistake.source.isEmpty ? "来源未填写" : mistake.source)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                        Label("根因：\(mistake.rootCausePreviewText)", systemImage: "stethoscope")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Label("信号：\(mistake.questionSignalPreviewText)", systemImage: "scope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(mistake.shortUpdatedDateText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("编辑错题手术")
            }

            HStack(spacing: 10) {
                Button {
                    onTap()
                } label: {
                    Label("继续手术", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Menu {
                    ForEach(ReviewStatusOption.all) { option in
                        Button {
                            onChangeStatus(option.status)
                        } label: {
                            Label(option.title, systemImage: option.systemImage)
                        }
                    }
                } label: {
                    Label(ReviewStatusOption.title(for: mistake.reviewStatus), systemImage: "chevron.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("切换复习状态")
            }

            Button {
                onGeneratePrompt()
            } label: {
                Label("生成错题 Prompt", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct MistakeQuestionThumbnail: View {
    let path: String
    let onTap: (String) -> Void

    var body: some View {
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)

        if let image = MistakeImageStore.loadImage(path: cleanPath) {
            Button {
                onTap(cleanPath)
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                        }

                    Image(systemName: "magnifyingglass")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开题图预览")
        } else if !cleanPath.isEmpty {
            Button {
                onTap(cleanPath)
            } label: {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 58, height: 58)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("题图读取失败，打开说明")
        }
    }
}

struct MistakeTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct MistakeStatusBadge: View {
    let status: String

    var body: some View {
        Label(ReviewStatusOption.title(for: status), systemImage: ReviewStatusOption.systemImage(for: status))
            .font(.caption.weight(.semibold))
            .foregroundStyle(ReviewStatusOption.tint(for: status))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct MistakeSurgeryCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension MistakeRecord {
    var surgerySubjectText: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未设科目"
            : LearningSubject.from(subject).displayName
    }

    var questionPreviewText: String {
        let text = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            return text
        }

        return questionImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未填写题面，先记录错因也可以。"
            : "已上传题图，题面文字未填写。"
    }

    var rootCausePreviewText: String {
        let text = rootCause.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "根因未填写" : text
    }

    var questionSignalPreviewText: String {
        let text = questionSignal.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "题目信号未填写" : text
    }

    var shortUpdatedDateText: String {
        "更新 \(Self.shortDateFormatter.string(from: updatedAt))"
    }

    var promptValues: [String: String] {
        [
            "subject": subject,
            "chapter": chapter,
            "question": questionPromptText,
            "mySolution": mySolution,
            "correctAnswer": correctSolution,
            "currentConfusion": currentConfusionText
        ]
    }

    private var questionPromptText: String {
        let text = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty else {
            return text
        }

        return questionImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "题目文字和题图都未提供，请先补充题面。"
            : "题目文字未填写。本错题有本地题图，请我在 AI 对话中同时上传图片，或先补充题面文字。"
    }

    private var currentConfusionText: String {
        let parts = [
            labeledPromptPart(title: "根因", value: rootCause),
            labeledPromptPart(title: "题目信号", value: questionSignal),
            labeledPromptPart(title: "正确模型", value: correctModel)
        ].compactMap { $0 }

        return parts.joined(separator: "\n")
    }

    private func labeledPromptPart(title: String, value: String) -> String? {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : "\(title)：\(text)"
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

struct MistakeTypeOption: Identifiable {
    let type: MistakeType
    let systemImage: String

    var id: String { type.rawValue }

    var title: String { type.displayName }

    static let all: [MistakeTypeOption] = [
        MistakeTypeOption(type: .concept, systemImage: "book.closed"),
        MistakeTypeOption(type: .method, systemImage: "point.3.connected.trianglepath.dotted"),
        MistakeTypeOption(type: .calculation, systemImage: "function"),
        MistakeTypeOption(type: .reading, systemImage: "text.magnifyingglass"),
        MistakeTypeOption(type: .model, systemImage: "cube.transparent"),
        MistakeTypeOption(type: .expression, systemImage: "text.quote"),
        MistakeTypeOption(type: .time, systemImage: "clock"),
        MistakeTypeOption(type: .other, systemImage: "ellipsis.circle")
    ]

    static func title(for type: String) -> String {
        type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未分类"
            : MistakeType.from(type).displayName
    }

    static func systemImage(for type: String) -> String {
        let normalizedType = MistakeType.from(type)
        return all.first { $0.type == normalizedType }?.systemImage ?? "questionmark.circle"
    }
}

struct ReviewStatusOption: Identifiable {
    let status: ReviewStatus
    let systemImage: String

    var id: String { status.rawValue }

    var title: String { status.displayName }

    var tint: Color {
        switch status {
        case .scheduled:
            return .blue
        case .reviewed:
            return .green
        case .mastered:
            return .purple
        default:
            return .orange
        }
    }

    static let all: [ReviewStatusOption] = [
        ReviewStatusOption(status: .new, systemImage: "sparkle"),
        ReviewStatusOption(status: .scheduled, systemImage: "calendar.badge.clock"),
        ReviewStatusOption(status: .reviewed, systemImage: "checkmark.circle"),
        ReviewStatusOption(status: .mastered, systemImage: "graduationcap")
    ]

    static func title(for status: String) -> String {
        status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "未知状态"
            : ReviewStatus.from(status).displayName
    }

    static func systemImage(for status: String) -> String {
        let normalizedStatus = ReviewStatus.from(status)
        return all.first { $0.status == normalizedStatus }?.systemImage ?? "questionmark.circle"
    }

    static func tint(for status: String) -> Color {
        let normalizedStatus = ReviewStatus.from(status)
        return all.first { $0.status == normalizedStatus }?.tint ?? .secondary
    }
}
