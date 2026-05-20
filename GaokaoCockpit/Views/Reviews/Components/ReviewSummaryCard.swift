import SwiftUI

struct ReviewActionButtons: View {
    let saveTitle: String
    let promptTitle: String
    let onSave: () -> Void
    let onGeneratePrompt: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button {
                onSave()
            } label: {
                Label(saveTitle, systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                onGeneratePrompt()
            } label: {
                Label(promptTitle, systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

struct ReviewStatsGrid: View {
    let stats: [ReviewStat]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(stats) { stat in
                ReviewStatTile(stat: stat)
            }
        }
    }
}

struct ReviewStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    var tint: Color = .primary
}

struct ReviewStatTile: View {
    let stat: ReviewStat

    var body: some View {
        VStack(spacing: 4) {
            Text(stat.value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(stat.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(stat.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ReviewTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .accessibilityLabel(title)

                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
            }
        }
    }
}

struct ReviewBreakdownBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(text.isEmpty ? "暂无记录" : text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .textSelection(.enabled)
        }
    }
}

struct ReviewCard<Content: View>: View {
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

struct ReviewSectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
    }
}

extension MistakeRecord {
    var displayTitle: String {
        let subjectText = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceText = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let chapterText = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let typeText = mistakeType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ""
            : MistakeType.from(mistakeType).displayName

        let headline = [subjectText, chapterText, typeText]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")

        if !sourceText.isEmpty {
            return headline.isEmpty ? sourceText : "\(headline) · \(sourceText)"
        }

        return headline.isEmpty ? "未命名错题" : headline
    }
}
