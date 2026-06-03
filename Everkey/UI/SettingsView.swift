import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: EverkeySettings

    /// Injected từ AppDelegate — dùng EventTapManager để capture hotkey
    var onStartCapture: ((@escaping (Hotkey) -> Void) -> Void)?
    var onCancelCapture: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                        HStack {
                            Text("Phím hoàn tác:")
                                .foregroundColor(.secondary)
                                .frame(width: 110, alignment: .leading)
                            HotkeyRecorderView(
                                hotkey: undoHotkeyBinding,
                                onStartCapture: onStartCapture,
                                onCancelCapture: onCancelCapture
                            )
                            .frame(maxWidth: 220)
                        }
                    }
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 460, height: settings.undoEnabled ? 230 : 180)
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
