import SwiftUI

struct ToastOverlay: View {
    @State private var manager = ToastManager.shared

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let toast = manager.currentToast {
                    HStack(spacing: 10) {
                        Image(systemName: toast.style.icon)
                            .foregroundStyle(toast.style.color)
                            .font(.system(size: 18, weight: .semibold))

                        Text(toast.message)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        Button {
                            manager.dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(toast.style.backgroundColor)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.thinMaterial)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(toast.style.color.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, geometry.safeAreaInsets.top + 8)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                }

                Spacer()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: manager.currentToast?.id)
        }
        .ignoresSafeArea()
        .allowsHitTesting(manager.currentToast != nil)
    }
}
