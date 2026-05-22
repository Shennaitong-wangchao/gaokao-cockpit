import SwiftUI

struct TomorrowFirstActionCard: View {
    @Binding var text: String

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: "明日第一步", systemImage: "arrow.forward.circle")

                LabeledTextEditor(
                    title: "明天打开 App 后第一件事",
                    subtitle: "写一句能直接执行的话",
                    placeholder: "明天打开 App 后第一件事",
                    text: $text,
                    minHeight: 70
                )
            }
        }
    }
}

struct SavePlanCard: View {
    let saveMessage: String?
    let onSave: () -> Void

    var body: some View {
        TodayCard {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    onSave()
                } label: {
                    Label("保存今日计划", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("保存今日计划")
                .accessibilityHint("将当前编辑内容写回今日计划")
                .accessibilityAddTraits(.isButton)

                if let saveMessage {
                    Label(saveMessage, systemImage: saveMessage.hasPrefix("保存失败") ? "exclamationmark.triangle" : "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(saveMessage.hasPrefix("保存失败") ? Color.red : Color.green)
                } else {
                    Text("编辑内容会先留在本页，点击按钮后统一写回 DayPlan。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#if DEBUG
struct DeveloperDiagnosticsDisclosureCard: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Stage2DebugPersistenceView()
                .padding(.top, 10)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label("开发诊断 / Developer Diagnostics", systemImage: "wrench.and.screwdriver")
                    .font(.footnote.weight(.semibold))
                Text("仅 DEBUG 构建显示，用于本地持久化检查。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
#endif
