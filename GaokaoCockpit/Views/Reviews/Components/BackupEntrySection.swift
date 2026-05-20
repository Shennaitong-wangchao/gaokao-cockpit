import SwiftUI

struct ReviewBackupEntryCard: View {
    let onOpenBackup: () -> Void

    var body: some View {
        ReviewCard {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("数据与备份", systemImage: "externaldrive")
                        .font(.subheadline.weight(.semibold))

                    Text("导出本地 JSON 备份，不包含导入恢复。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onOpenBackup()
                } label: {
                    Label("导出本地备份", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
