import Foundation
import SwiftUI

struct TodayHeaderView: View {
    let date: Date
    let dayKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日驾驶舱")
                .font(.largeTitle.bold())

            Text(Self.dateFormatter.string(from: date))
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text(dayKey)
                Text("每天启动、专注、错题、复盘")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}

struct TodayStartupCard: View {
    @Binding var stateScore: Int
    @Binding var mainSubject: String

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "今日启动", systemImage: "sun.max")

                Stepper(value: $stateScore, in: 1...10) {
                    HStack {
                        Text("状态评分")
                        Spacer()
                        Text("\(stateScore)/10")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(stateScore <= 4 ? .orange : .primary)
                    }
                }
                .accessibilityLabel("状态评分")
                .accessibilityValue("\(stateScore) 分")

                VStack(alignment: .leading, spacing: 8) {
                    Text("主攻科目")
                        .font(.subheadline.weight(.semibold))

                    Picker("主攻科目", selection: subjectSelection) {
                        ForEach(LearningSubject.allCases) { subject in
                            Text(subject.displayName).tag(subject.storageValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("主攻科目")
                }
            }
        }
    }

    private var subjectSelection: Binding<String> {
        Binding(
            get: {
                LearningSubject.from(mainSubject).storageValue
            },
            set: { newValue in
                mainSubject = LearningSubject.from(newValue).storageValue
            }
        )
    }
}
