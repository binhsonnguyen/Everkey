import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    private let settings: EverkeySettings
    private let onStartCapture: ((@escaping (Hotkey) -> Void) -> Void)?
    private let onCancelCapture: (() -> Void)?

    init(settings: EverkeySettings,
         onStartCapture: ((@escaping (Hotkey) -> Void) -> Void)?,
         onCancelCapture: (() -> Void)?) {
        self.settings = settings
        self.onStartCapture = onStartCapture
        self.onCancelCapture = onCancelCapture

        let view = SettingsView(
            settings: settings,
            onStartCapture: onStartCapture,
            onCancelCapture: onCancelCapture
        )
        let hosting = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Everkey"
        window.contentView = hosting
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func showSettings() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
