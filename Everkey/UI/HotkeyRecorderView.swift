import SwiftUI
import AppKit

// Presets người dùng có thể chọn nhanh
private struct HotkeyPreset: Identifiable {
    let id = UUID()
    let label: String
    let hotkey: Hotkey
    static let all: [HotkeyPreset] = [
        HotkeyPreset(label: "⌃Space",  hotkey: Hotkey(keyCode: 49, modifiers: [.control])),
        HotkeyPreset(label: "⌥Z",      hotkey: Hotkey(keyCode: 6,  modifiers: [.option])),
        HotkeyPreset(label: "⌃⌥Space", hotkey: Hotkey(keyCode: 49, modifiers: [.control, .option])),
        HotkeyPreset(label: "⌘⌥T",     hotkey: Hotkey(keyCode: 0x11, modifiers: [.command, .option])),
        HotkeyPreset(label: "⌘⇧V",     hotkey: Hotkey(keyCode: 9,  modifiers: [.command, .shift])),
    ]
}

struct HotkeyRecorderView: View {
    @Binding var hotkey: Hotkey

    /// Gọi khi muốn bắt đầu capture. Nhận vào closure gọi lại với Hotkey mới.
    var onStartCapture: ((@escaping (Hotkey) -> Void) -> Void)?
    /// Gọi khi cancel capture.
    var onCancelCapture: (() -> Void)?

    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggleRecording) {
                HStack {
                    Spacer()
                    Text(isRecording ? "Nhấn phím tắt..." : (displayText.isEmpty ? "Chưa đặt" : displayText))
                        .foregroundColor(isRecording ? .red : (displayText.isEmpty ? .secondary : .primary))
                        .font(.system(size: 12, design: .monospaced))
                    Spacer()
                }
                .frame(height: 28)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.red : Color.gray.opacity(0.3), lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            Menu {
                ForEach(HotkeyPreset.all) { preset in
                    Button(preset.label) { applyPreset(preset.hotkey) }
                }
            } label: {
                Image(systemName: "chevron.down.circle")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 22)

            Button(action: clear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var displayText: String {
        guard hotkey.keyCode != 0 || !hotkey.modifiers.isEmpty else { return "" }
        return hotkey.displayString
    }

    private func toggleRecording() {
        if isRecording {
            isRecording = false
            onCancelCapture?()
        } else {
            isRecording = true
            onStartCapture? { newHotkey in
                DispatchQueue.main.async {
                    self.hotkey = newHotkey
                    self.isRecording = false
                }
            }
        }
    }

    private func applyPreset(_ h: Hotkey) {
        if isRecording { isRecording = false; onCancelCapture?() }
        hotkey = h
    }

    private func clear() {
        if isRecording { isRecording = false; onCancelCapture?() }
        hotkey = Hotkey(keyCode: 0, modifiers: [])
    }
}
