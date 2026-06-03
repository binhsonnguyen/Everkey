//
//  SettingsWindowController.swift
//  Everkey
//

import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    private let settings: EverkeySettings

    init(settings: EverkeySettings) {
        self.settings = settings
        let view = SettingsView(settings: settings)
        let hosting = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 200),
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
