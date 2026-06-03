import SwiftUI
import EverkeyEngine

// MARK: - Main

struct StatusMenuView: View {
    @ObservedObject var viewModel: StatusBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            popoverRow {
                HStack {
                    Text("Gõ Tiếng Việt")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.isVietnamese },
                        set: { _ in viewModel.toggleVietnamese() }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
                }
            }

            popoverDivider()

            popoverActionRow(icon: "gearshape", title: "Bảng điều khiển...") {
                viewModel.openSettings()
            }

            popoverDivider()

            popoverActionRow(icon: "power", title: "Thoát Everkey") {
                viewModel.quit()
            }
        }
        .padding(.vertical, 4)
        .frame(width: 240)
    }

    // MARK: - Helpers

    private func popoverRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
    }

    private func popoverDivider() -> some View {
        Divider()
            .padding(.horizontal, 8)
    }

    private func popoverActionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        PopoverActionRow(icon: icon, title: title, action: action)
    }
}

private struct PopoverActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

#if DEBUG
#Preview {
    StatusMenuView(viewModel: StatusBarViewModel())
        .background(Color(nsColor: .windowBackgroundColor))
}
#endif
