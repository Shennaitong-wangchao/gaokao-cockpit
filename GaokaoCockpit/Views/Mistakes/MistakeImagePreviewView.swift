import SwiftUI
import UIKit

struct MistakeImagePreviewItem: Identifiable {
    let id = UUID()
    let path: String

    init?(path: String) {
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPath.isEmpty else {
            return nil
        }

        self.path = cleanPath
    }
}

struct MistakeImagePreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let path: String

    @State private var baseScale: CGFloat = 1
    @GestureState private var pinchScale: CGFloat = 1

    private var image: UIImage? {
        MistakeImageStore.loadImage(path: path)
    }

    private var currentScale: CGFloat {
        min(max(baseScale * pinchScale, 1), 4)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let image {
                    GeometryReader { proxy in
                        ScrollView([.horizontal, .vertical]) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: proxy.size.width)
                                .scaleEffect(currentScale)
                                .padding(.vertical, 20)
                                .frame(minHeight: proxy.size.height)
                                .accessibilityLabel("题图预览")
                        }
                        .background(Color(.systemBackground))
                        .gesture(
                            MagnificationGesture()
                                .updating($pinchScale) { value, state, _ in
                                    state = value
                                }
                                .onEnded { value in
                                    baseScale = min(max(baseScale * value, 1), 4)
                                }
                        )
                        .onTapGesture(count: 2) {
                            baseScale = baseScale > 1 ? 1 : 2
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("题图读取失败", systemImage: "photo.badge.exclamationmark")
                    } description: {
                        Text("题图读取失败，可能文件已被移动或删除。")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("题图预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}
