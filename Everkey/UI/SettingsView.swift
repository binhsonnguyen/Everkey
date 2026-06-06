import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: EverkeySettings
    @StateObject private var launchAtLogin = LaunchAtLogin()

    /// Injected từ AppDelegate — dùng EventTapManager để capture hotkey
    var onStartCapture: ((@escaping (Hotkey) -> Void) -> Void)?
    var onCancelCapture: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if launchAtLogin.isAvailable {
                settingsGroup(header: "HỆ THỐNG") {
                    Toggle("Khởi động cùng macOS", isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    ))
                }
            }

            settingsGroup(header: "PHÍM TẮT") {
                settingsRow(label: "Chuyển VN/EN") {
                    HotkeyRecorderView(
                        hotkey: $settings.toggleHotkey,
                        onStartCapture: onStartCapture,
                        onCancelCapture: onCancelCapture
                    )
                    .frame(maxWidth: 220)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Bật hoàn tác gõ", isOn: $settings.undoEnabled)
                    if settings.undoEnabled {
                        // Cùng cấu trúc với settingsRow (label 120 + Spacer cuối) để field
                        // và cụm icon thẳng cột với hàng "Chuyển VN/EN" phía trên.
                        HStack(alignment: .center) {
                            Text("Phím hoàn tác:")
                                .foregroundColor(.secondary)
                                .frame(width: 120, alignment: .leading)
                            HotkeyRecorderView(
                                hotkey: undoHotkeyBinding,
                                onStartCapture: onStartCapture,
                                onCancelCapture: onCancelCapture
                            )
                            .frame(maxWidth: 220)
                            Spacer()
                        }
                        Toggle("Hoặc nhấn Shift trái + Shift phải", isOn: $settings.undoUsesDoubleShift)
                    }
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 4)
            }

            Spacer()

            Text("Everkey \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .frame(width: 460, height: contentHeight)
    }

    private var contentHeight: CGFloat {
        var height: CGFloat = settings.undoEnabled ? 262 : 180
        if launchAtLogin.isAvailable { height += 76 }
        return height
    }

    private func settingsGroup<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(header)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 6)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func settingsRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .frame(width: 120, alignment: .leading)
            content()
            Spacer()
        }
    }

    private var undoHotkeyBinding: Binding<Hotkey> {
        Binding(
            get: { settings.undoHotkey ?? Hotkey(keyCode: 0x35, modifiers: []) },
            set: { settings.undoHotkey = $0 }
        )
    }
}
