import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let eventTapManager = EventTapManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()

        if !checkAccessibilityPermission() {
            promptAccessibilityPermission()
        }

        setupEventTap()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "V"
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Everkey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    // MARK: - Event Tap

    private func setupEventTap() {
        eventTapManager.onEvent = { proxy, type, event in
            // Temporary: log keyDown events to verify interception
            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                NSLog("[Everkey] keyDown: keyCode=\(keyCode)")
            }
            return Unmanaged.passUnretained(event)
        }

        if !eventTapManager.start() {
            NSLog("[Everkey] Failed to create event tap. Check Accessibility permission.")
        }
    }

    // MARK: - Accessibility Permission

    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func promptAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
