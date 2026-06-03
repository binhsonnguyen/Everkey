import SwiftUI
import EverkeyEngine

struct SettingsView: View {
    @ObservedObject var settings: EverkeySettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsSection(header: "PHÍM TẮT") {
                settingsRow(label: "Chuyển VN/EN") {
                    HotkeyRecorderView(hotkey: $settings.toggleHotkey)
                }
                Divider().padding(.leading, 16)
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Hoàn tác gõ", isOn: $settings.undoEnabled)
                    if settings.undoEnabled {
                        HotkeyRecorderView(hotkey: undoHotkeyBinding)
                            .padding(.leading, 0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            settingsSection(header: "NHẬP LIỆU") {
                settingsRow(label: "Kiểu gõ") {
                    Picker("", selection: $settings.inputMethod) {
                        Text(InputMethod.telex.displayName).tag(InputMethod.telex)
                        Text(InputMethod.vni.displayName).tag(InputMethod.vni)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 180)
                }
                Divider().padding(.leading, 16)
                settingsRow(label: "Phát hiện tiếng Anh") {
                    Toggle("", isOn: $settings.spellCheckEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 480, height: 320)
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(header)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 6)
            VStack(spacing: 0) {
                content()
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func settingsRow<Content: View>(label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(label)
                .frame(width: 160, alignment: .leading)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var undoHotkeyBinding: Binding<Hotkey> {
        Binding(
            get: { settings.undoHotkey ?? Hotkey(keyCode: 0x35, modifiers: [], isModifierOnly: false) },
            set: { settings.undoHotkey = $0 }
        )
    }
}
