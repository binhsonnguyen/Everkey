import Cocoa
import SwiftUI
import Combine
import EverkeyEngine

class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Core

    private let settings = EverkeySettings.shared
    private let eventTapManager = EventTapManager()
    private let textInjector = CGTextInjector()
    private var keyboardHandler: KeyboardEventHandler!

    // MARK: - Status bar

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var statusMenuViewModel: StatusBarViewModel!
    private var settingsWindowController: SettingsWindowController?

    // MARK: - App-switch state

    private var languagePerApp: [String: Bool] = [:]
    private var previousBundleID: String?

    // MARK: - Modifier-only hotkey state (tracked in onEvent closure)

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

    // MARK: - Status Bar (SwiftUI popover)

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarIcon(isVietnamese: true)

        statusMenuViewModel = StatusBarViewModel()
        statusMenuViewModel.isVietnamese = keyboardHandler.isVietnamese
        statusMenuViewModel.onToggleVietnamese = { [weak self] in
            guard let self else { return }
            self.keyboardHandler.setVietnameseMode(!self.keyboardHandler.isVietnamese)
        }
        statusMenuViewModel.onOpenSettings = { [weak self] in self?.openSettings() }
        statusMenuViewModel.onQuit = { NSApplication.shared.terminate(nil) }

        let menuController = NSHostingController(rootView: StatusMenuView(viewModel: statusMenuViewModel))
        menuController.view.frame = NSRect(x: 0, y: 0, width: 240, height: 140)
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = menuController
        popover.contentSize = NSSize(width: 240, height: 140)

        keyboardHandler.onToggle = { [weak self] isVietnamese in
            self?.updateStatusBarIcon(isVietnamese: isVietnamese)
        }

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseDown])
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func updateStatusBarIcon(isVietnamese: Bool) {
        statusItem?.button?.title = isVietnamese ? "V" : "E"
        statusMenuViewModel?.isVietnamese = isVietnamese
    }

    // MARK: - Settings Window

    private func openSettings() {
        popover.performClose(nil)
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settings: settings)
        }
        settingsWindowController?.showSettings()
    }

    // MARK: - Event Tap

    private func setupEventTap() {
        eventTapManager.onEvent = { [weak self] proxy, type, event in
            guard let self else { return Unmanaged.passUnretained(event) }

            // ── Configurable toggle hotkey ─────────────────────────────────────
            let hotkey = self.settings.toggleHotkey
            if hotkey.isModifierOnly {
                // Modifier-only: trigger on full-release after holding required mods
                if type == .flagsChanged {
                    let eventMods = ModifierFlags(from: event.flags)
                    let allMods: ModifierFlags = [.control, .shift, .option, .command, .function]
                    let hasExactly = hotkey.modifiers.isSubset(of: eventMods)
                        && eventMods.intersection(allMods) == hotkey.modifiers
                    if hasExactly {
                        if !self.modOnlyReached {
                            self.modOnlyReached = true
                            self.modOnlyTriggered = false
                        }
                    } else {
                        if self.modOnlyReached && !self.modOnlyTriggered {
                            self.modOnlyTriggered = true
                            DispatchQueue.main.async {
                                self.keyboardHandler.setVietnameseMode(!self.keyboardHandler.isVietnamese)
                            }
                        }
                        self.modOnlyReached = false
                    }
                } else if type == .keyDown && self.modOnlyReached {
                    self.modOnlyReached = false
                    self.modOnlyTriggered = true
                }
            } else if type == .keyDown {
                // Regular key+modifier hotkey
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let eventMods = ModifierFlags(from: event.flags)
                if keyCode == hotkey.keyCode && eventMods == hotkey.modifiers {
                    DispatchQueue.main.async {
                        self.keyboardHandler.setVietnameseMode(!self.keyboardHandler.isVietnamese)
                    }
                    return nil  // consume
                }
            }

            // ── Configurable undo hotkey ───────────────────────────────────────
            if self.settings.undoEnabled && type == .keyDown {
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let eventMods = ModifierFlags(from: event.flags)
                let triggered: Bool
                if let undo = self.settings.undoHotkey {
                    triggered = keyCode == undo.keyCode && eventMods == undo.modifiers
                } else {
                    triggered = keyCode == 0x35 && eventMods.isEmpty  // Escape
                }
                if triggered {
                    DispatchQueue.main.async { _ = self.keyboardHandler.performUndo() }
                    return nil
                }
            }

            // ── Normal event processing ────────────────────────────────────────
            self.textInjector.currentProxy = proxy
            let keyEvent = CGEventAdapter.adapt(event: event, type: type)
            let suppress = self.keyboardHandler.handleEvent(keyEvent)
            return suppress ? nil : Unmanaged.passUnretained(event)
        }

        if !eventTapManager.start() {
            NSLog("[Everkey] Failed to create event tap. Check Accessibility permission.")
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
              let bundleID = app.bundleIdentifier else {
            keyboardHandler.resetEngine()
            return
        }
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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func promptAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
