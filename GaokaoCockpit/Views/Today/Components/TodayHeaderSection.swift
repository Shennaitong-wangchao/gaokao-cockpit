import Foundation
import SwiftUI

struct TodayHeaderView: View {
    let date: Date
    let dayKey: String
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // 标题和日期
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("今日驾驶舱")
                        .font(DesignSystem.Typography.largeTitle)
                        .foregroundStyle(themeManager.themeColor)

                    Text(Self.dateFormatter.string(from: date))
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(.primary)
                }

                Spacer()

                // 主题色指示器
                Circle()
                    .fill(themeManager.themeColor)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .stroke(themeManager.themeColor.opacity(0.3), lineWidth: 4)
                    }
            }

            // 副标题和激励语
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(dayKey)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(.secondary)

                Text(EncouragementSystem.getGreeting())
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(themeManager.themeColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    themeManager.themeColor.opacity(0.08),
                    themeManager.themeColor.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = AppDateTime.timeZone
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}

struct TodayStartupCard: View {
    @Binding var stateScore: Int
    @Binding var mainSubject: String
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        DSCard(
            cornerRadius: DesignSystem.CornerRadius.large,
            shadow: DesignSystem.Shadow.medium,
            accentColor: themeManager.themeColor
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                SectionTitle(title: "今日启动", systemImage: "sun.max")

                HStack(spacing: DesignSystem.Spacing.xl) {
                    // 状态分数环形图
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        ZStack {
                            DSProgressBar(
                                progress: Double(stateScore) / 10.0,
                                style: .ring(lineWidth: 10),
                                color: scoreColor,
                                showPercentage: false
                            )
                            .frame(width: 80, height: 80)

                            VStack(spacing: 2) {
                                Text("\(stateScore)")
                                    .font(DesignSystem.Typography.numberLarge)
                                    .foregroundStyle(scoreColor)
                                Text("/ 10")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(scoreDescription)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(scoreColor)

                        Text(EncouragementSystem.getStateMessage(for: stateScore))
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // 状态调整和主攻科目
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        // 状态评分调整
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("状态评分")
                                .font(DesignSystem.Typography.subheadline.weight(.semibold))

                            Stepper(value: $stateScore, in: 1...10) {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    ForEach(1...10, id: \.self) { score in
                                        Circle()
                                            .fill(score <= stateScore ? scoreColor : Color.gray.opacity(0.2))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                            .accessibilityLabel("状态评分")
                            .accessibilityValue("\(stateScore) 分")
                            .accessibilityHint("上滑或下滑调整 1 到 10 分")
                        }

                        Divider()

                        // 主攻科目
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("主攻科目")
                                .font(DesignSystem.Typography.subheadline.weight(.semibold))

                            Picker("主攻科目", selection: subjectSelection) {
                                Text("先选主攻科目").tag("")
                                ForEach(LearningSubject.allCases) { subject in
                                    Text(subject.displayName).tag(subject.storageValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("主攻科目")
                            .accessibilityValue(mainSubject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未选择" : LearningSubject.from(mainSubject).displayName)
                            .accessibilityHint("选择今天主要投入的学科")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                }
            }
        }
    }

    private var scoreColor: Color {
        switch stateScore {
        case 1...4: return DesignSystem.SemanticColors.error
        case 5...6: return DesignSystem.SemanticColors.warning
        case 7...8: return DesignSystem.SemanticColors.info
        default: return DesignSystem.SemanticColors.success
        }
    }

    private var scoreDescription: String {
        switch stateScore {
        case 1...4: return "低能量"
        case 5...6: return "一般"
        case 7...8: return "良好"
        default: return "极佳"
        }
    }

    private var subjectSelection: Binding<String> {
        Binding(
            get: {
                let trimmedSubject = mainSubject.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedSubject.isEmpty else {
                    return ""
                }

                return LearningSubject.from(trimmedSubject).storageValue
            },
            set: { newValue in
                mainSubject = newValue.isEmpty ? "" : LearningSubject.from(newValue).storageValue
            }
        )
    }
}
