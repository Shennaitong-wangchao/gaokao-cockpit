import SwiftUI

@Observable
final class ToastManager {
    static let shared = ToastManager()

    var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    func show(message: String, style: ToastStyle = .info, duration: Duration = .seconds(2.5)) {
        dismissTask?.cancel()

        currentToast = ToastItem(
            message: message,
            style: style,
            duration: duration
        )

        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.35)) {
                self.currentToast = nil
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.35)) {
            currentToast = nil
        }
    }
}

struct ToastItem: Identifiable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let duration: Duration
}

enum ToastStyle {
    case success, error, warning, info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.12)
        case .error: return Color.red.opacity(0.12)
        case .warning: return Color.orange.opacity(0.12)
        case .info: return Color.blue.opacity(0.12)
        }
    }
}
