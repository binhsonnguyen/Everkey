import Cocoa
import SwiftUI
import EverkeyEngine

class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Core

    private let settings = EverkeySettings.shared
    private let eventTapManager = EventTapManager()
    private let textInjector = CGTextInjector()
    private var keyboardHandler: KeyboardEventHandler!

    // MARK: - Status bar

    private var statusItem: NSStatusItem!
    private var vietnameseMenuItem: NSMenuItem!
    private var settingsWindowController: SettingsWindowController?

    // MARK: - App-switch state

    private var languagePerApp: [String: Bool] = [:]
    private var previousBundleID: String?

    // MARK: - Hotkey capture (for settings recorder)

    var hotkeyCaptureCallback: ((Hotkey) -> Void)?

    // MARK: - Modifier-only hotkey state

    private var modOnlyReached = false
    private var modOnlyTriggered = false

    private static let browserBundleIDs: Set<String> = [
        "com.apple.Safari", "com.google.Chrome", "com.google.Chrome.canary",
        "com.brave.Browser", "com.microsoft.edgemac", "company.thebrowser.Browser",
        "com.operasoftware.Opera", "com.vivaldi.Vivaldi", "org.mozilla.firefox",
    ]

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        keyboardHandler = KeyboardEventHandler(injector: textInjector)
        setupStatusBar()
        if !checkAccessibilityPermission() { promptAccessibilityPermission() }
        setupEventTap()
        setupAppSwitchObserver()
        setupSleepWakeObserver()
    }

    // MARK: - Status Bar (NSMenu)

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateStatusBarIcon(isVietnamese: true)
        statusItem.menu = buildMenu()

        keyboardHandler.onToggle = { [weak self] isVietnamese in
            self?.updateStatusBarIcon(isVietnamese: isVietnamese)
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        vietnameseMenuItem = NSMenuItem(
            title: "Gõ Tiếng Việt",
            action: #selector(toggleVietnamese),
            keyEquivalent: ""
        )
        vietnameseMenuItem.target = self
        vietnameseMenuItem.state = .on
        // macOS 26 dành cột icon cho menu; gắn symbol để item này thẳng hàng với
        // Settings/Quit (vốn được hệ thống tự gán icon) thay vì thụt sang trái.
        vietnameseMenuItem.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Gõ Tiếng Việt")
        menu.addItem(vietnameseMenuItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Bảng điều khiển...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Thoát Everkey",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        return menu
    }

    @objc private func toggleVietnamese() {
        keyboardHandler.setVietnameseMode(!keyboardHandler.isVietnamese)
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                settings: settings,
                onStartCapture: { [weak self] callback in
                    self?.hotkeyCaptureCallback = callback
                },
                onCancelCapture: { [weak self] in
                    self?.hotkeyCaptureCallback = nil
                }
            )
        }
        settingsWindowController?.showSettings()
    }

    private func updateStatusBarIcon(isVietnamese: Bool) {
        statusItem?.button?.image = StatusBarIconRenderer.makeImage(
            text: isVietnamese ? "V" : "E",
            filled: isVietnamese
        )
        statusItem?.button?.title = ""
        vietnameseMenuItem?.state = isVietnamese ? .on : .off
    }

    // MARK: - Event Tap

    private func setupEventTap() {
        eventTapManager.onEvent = { [weak self] proxy, type, event in
            guard let self else { return Unmanaged.passUnretained(event) }

            // ── Hotkey capture (settings recorder) ────────────────────────────
            if let capture = self.hotkeyCaptureCallback, type == .keyDown {
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let eventMods = ModifierFlags(from: event.flags)
                if keyCode == 0x35 {
                    self.hotkeyCaptureCallback = nil
                } else if !eventMods.isEmpty {
                    let newHotkey = Hotkey(keyCode: keyCode, modifiers: eventMods)
                    self.hotkeyCaptureCallback = nil
                    DispatchQueue.main.async { capture(newHotkey) }
                }
                return nil
            }

            // ── Configurable toggle hotkey ─────────────────────────────────────
            let hotkey = self.settings.toggleHotkey
            if hotkey.isModifierOnly {
                if type == .flagsChanged {
                    let eventMods = ModifierFlags(from: event.flags)
                    let allMods: ModifierFlags = [.control, .shift, .option, .command, .function]
                    let hasExactly = hotkey.modifiers.isSubset(of: eventMods)
                        && eventMods.intersection(allMods) == hotkey.modifiers
                    if hasExactly {
                        if !self.modOnlyReached { self.modOnlyReached = true; self.modOnlyTriggered = false }
                    } else {
                        if self.modOnlyReached && !self.modOnlyTriggered {
                            self.modOnlyTriggered = true
                            DispatchQueue.main.async { self.keyboardHandler.setVietnameseMode(!self.keyboardHandler.isVietnamese) }
                        }
                        self.modOnlyReached = false
                    }
                } else if type == .keyDown && self.modOnlyReached {
                    self.modOnlyReached = false; self.modOnlyTriggered = true
                }
            } else if type == .keyDown {
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let eventMods = ModifierFlags(from: event.flags)
                if keyCode == hotkey.keyCode && eventMods == hotkey.modifiers {
                    DispatchQueue.main.async { self.keyboardHandler.setVietnameseMode(!self.keyboardHandler.isVietnamese) }
                    return nil
                }
            }

            // ── Configurable undo hotkey ───────────────────────────────────────
            if self.settings.undoEnabled && type == .keyDown {
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let eventMods = ModifierFlags(from: event.flags)
                let triggered = self.settings.undoHotkey.map { keyCode == $0.keyCode && eventMods == $0.modifiers }
                    ?? (keyCode == 0x35 && eventMods.isEmpty)
                if triggered {
                    DispatchQueue.main.async { _ = self.keyboardHandler.performUndo() }
                    return nil
                }
            }

            // ── Normal processing ──────────────────────────────────────────────
            self.textInjector.currentProxy = proxy
            let keyEvent = CGEventAdapter.adapt(event: event, type: type)
            let suppress = self.keyboardHandler.handleEvent(keyEvent)
            return suppress ? nil : Unmanaged.passUnretained(event)
        }

        if !eventTapManager.start() {
            NSLog("[Everkey] Failed to create event tap.")
        }
    }

    // MARK: - App Switch

    private func setupAppSwitchObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(activeAppChanged),
            name: NSWorkspace.didActivateApplicationNotification, object: nil
        )
    }

    @objc private func activeAppChanged(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { keyboardHandler.resetEngine(); return }
        if let prev = previousBundleID { languagePerApp[prev] = keyboardHandler.isVietnamese }
        keyboardHandler.resetEngine()
        let saved = languagePerApp[bundleID] ?? true
        keyboardHandler.setVietnameseMode(saved)
        textInjector.needsAutocompleteFix = Self.browserBundleIDs.contains(bundleID)
        previousBundleID = bundleID
    }

    // MARK: - Sleep/Wake

    private func setupSleepWakeObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    @objc private func handleSleep() { eventTapManager.stop() }
    @objc private func handleWake() {
        if !eventTapManager.start() { NSLog("[Everkey] Failed to recreate event tap after wake.") }
    }

    // MARK: - Accessibility

    private func checkAccessibilityPermission() -> Bool {
        AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        )
    }

    private func promptAccessibilityPermission() {
        AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        )
    }
}
