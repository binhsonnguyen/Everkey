import Cocoa
import SwiftUI
import Combine
import EverkeyEngine

class AppDelegate: NSObject, NSApplicationDelegate {

    private let settings = EverkeySettings.shared
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var statusMenuViewModel: StatusBarViewModel!

    private let eventTapManager = EventTapManager()
    private let textInjector = CGTextInjector()
    private var keyboardHandler: KeyboardEventHandler!

    private var settingsWindowController: SettingsWindowController?
    private var languagePerApp: [String: Bool] = [:]
    private var previousBundleID: String?
    private var cancellables = Set<AnyCancellable>()

    private static let browserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "company.thebrowser.Browser",
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi",
        "org.mozilla.firefox",
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        keyboardHandler = KeyboardEventHandler(injector: textInjector)

        setupStatusBar()

        if !checkAccessibilityPermission() {
            promptAccessibilityPermission()
        }

        setupEventTap()
        setupAppSwitchObserver()
        setupSleepWakeObserver()
        setupHotkeySync()
    }

    // MARK: - Status Bar

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
        // onToggle updates the status bar icon
        keyboardHandler.onToggle = { [weak self] isVietnamese in
            self?.updateStatusBarIcon(isVietnamese: isVietnamese)
        }

        eventTapManager.onEvent = { [weak self] proxy, type, event in
            guard let self else { return Unmanaged.passUnretained(event) }
            self.textInjector.currentProxy = proxy
            let keyEvent = CGEventAdapter.adapt(event: event, type: type)
            let suppress = self.keyboardHandler.handleEvent(keyEvent)
            return suppress ? nil : Unmanaged.passUnretained(event)
        }

        if !eventTapManager.start() {
            NSLog("[Everkey] Failed to create event tap. Check Accessibility permission.")
        }
    }

    // MARK: - Configurable hotkeys (EventTapManager)

    private func setupHotkeySync() {
        // Wire EventTapManager callbacks
        eventTapManager.onToggleHotkey = { [weak self] in
            guard let self else { return }
            self.keyboardHandler.setVietnameseMode(!self.keyboardHandler.isVietnamese)
        }
        eventTapManager.onUndoTyping = { [weak self] in
            _ = self?.keyboardHandler.performUndo()
        }

        // Apply stored settings
        applyHotkeySettings()

        // Re-apply when settings change
        settings.$toggleHotkey
            .dropFirst()
            .sink { [weak self] _ in self?.applyHotkeySettings() }
            .store(in: &cancellables)
        settings.$undoEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.applyHotkeySettings() }
            .store(in: &cancellables)
        settings.$undoHotkey
            .dropFirst()
            .sink { [weak self] _ in self?.applyHotkeySettings() }
            .store(in: &cancellables)

        // Suspend hotkey detection while recording
        NotificationCenter.default.addObserver(
            forName: .hotkeyRecordingStateChanged, object: nil, queue: .main
        ) { [weak self] note in
            let recording = (note.userInfo?["isRecording"] as? Bool) ?? false
            self?.eventTapManager.isHotkeyRecording = recording
        }
    }

    private func applyHotkeySettings() {
        eventTapManager.toggleHotkey = settings.toggleHotkey
        eventTapManager.undoEnabled = settings.undoEnabled
        eventTapManager.undoHotkey = settings.undoHotkey
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

        if let prev = previousBundleID {
            languagePerApp[prev] = keyboardHandler.isVietnamese
        }

        keyboardHandler.resetEngine()

        let savedState = languagePerApp[bundleID] ?? true
        keyboardHandler.setVietnameseMode(savedState)

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
        if !eventTapManager.start() {
            NSLog("[Everkey] Failed to recreate event tap after wake.")
        }
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
