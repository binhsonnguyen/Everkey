import SwiftUI
import EverkeyEngine

// MARK: - View Modifiers

private struct MenuCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal, 8)
    }
}

private extension View {
    func menuCardStyle() -> some View {
        modifier(MenuCardStyle())
    }
}

// MARK: - Reusable Row Components

struct MenuToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var action: (() -> Void)? = nil

    var body: some View {
        Toggle(title, isOn: $isOn)
            .toggleStyle(.switch)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onChange(of: isOn) { _ in
                action?()
            }
    }
}

struct MenuActionRow: View {
    let icon: String
    let title: String
    let shortcut: String?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16, height: 16)
                    .foregroundColor(.secondary)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if let shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered in isHovered = hovered }
    }
}

// MARK: - Input Method Picker

private struct InputMethodSection: View {
    @Binding var selectedMethod: InputMethod
    let onMethodChanged: (InputMethod) -> Void

    @State private var isExpanded = false

    private let availableMethods: [InputMethod] = [.telex, .vni]

    var body: some View {
        VStack(spacing: 0) {
            // Collapsible header
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Kiểu gõ")
                        .foregroundColor(.primary)

                    Spacer()

                    Text(selectedMethod.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded method list
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(availableMethods, id: \.self) { method in
                        InputMethodRow(
                            method: method,
                            isSelected: selectedMethod == method
                        ) {
                            selectedMethod = method
                            onMethodChanged(method)
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isExpanded = false
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }
}

private struct InputMethodRow: View {
    let method: InputMethod
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .opacity(isSelected ? 1 : 0)
                    .frame(width: 14)

                Text(method.displayName)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered in isHovered = hovered }
        .padding(.horizontal, 4)
    }
}

// MARK: - Main Menu View

struct StatusMenuView: View {
    @ObservedObject var viewModel: StatusBarViewModel

    var body: some View {
        VStack(spacing: 4) {
            // 1. Vietnamese toggle
            MenuToggleRow(
                title: "Gõ Tiếng Việt",
                isOn: $viewModel.isVietnamese
            ) {
                viewModel.toggleVietnamese()
            }
            .menuCardStyle()

            // 2. Input method section (collapsible)
            InputMethodSection(
                selectedMethod: $viewModel.inputMethod,
                onMethodChanged: { method in
                    viewModel.selectInputMethod(method)
                }
            )
            .menuCardStyle()

            // 3. Spell check toggle
            MenuToggleRow(
                title: "Phát hiện tiếng Anh",
                isOn: $viewModel.spellCheckEnabled
            ) {
                viewModel.toggleSpellCheck()
            }
            .menuCardStyle()

            // 4. Divider
            Divider()
                .padding(.horizontal, 8)

            // 5. Settings
            MenuActionRow(
                icon: "gearshape",
                title: "Bảng điều khiển...",
                shortcut: nil,
                action: { viewModel.openSettings() }
            )
            .menuCardStyle()

            // 6. Divider
            Divider()
                .padding(.horizontal, 8)

            // 7. Quit
            MenuActionRow(
                icon: "power",
                title: "Thoát Everkey",
                shortcut: nil,
                action: { viewModel.quit() }
            )
            .menuCardStyle()
        }
        .padding(.vertical, 6)
        .frame(width: 280)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    StatusMenuView(viewModel: StatusBarViewModel())
        .background(Color(nsColor: .windowBackgroundColor))
}
#endif
