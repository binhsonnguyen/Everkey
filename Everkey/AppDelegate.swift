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

    func applicationDidFinishLaunching(_ notification: Notification) {
        keyboardHandler = KeyboardEventHandler(injector: textInjector)
        applySettings()
        setupStatusBar()
        setupHotkeyObserver()

        if !checkAccessibilityPermission() {
            promptAccessibilityPermission()
        }

        setupEventTap()
        setupAppSwitchObserver()
        setupSleepWakeObserver()
    }

    // MARK: - Settings → Engine + EventTap

    private func applySettings() {
        keyboardHandler.setInputMethod(settings.inputMethod)
        keyboardHandler.setEnglishDetection(enabled: settings.spellCheckEnabled)

        eventTapManager.toggleHotkey = settings.toggleHotkey
        eventTapManager.undoEnabled = settings.undoEnabled
        eventTapManager.undoHotkey = settings.undoHotkey

        eventTapManager.onToggleHotkey = { [weak self] in
            guard let self else { return }
            let newState = !self.keyboardHandler.isVietnamese
            self.keyboardHandler.setVietnameseMode(newState)
            self.statusMenuViewModel.isVietnamese = newState
            self.updateStatusBarIcon(isVietnamese: newState)
        }

        eventTapManager.onUndoTyping = { [weak self] in
            _ = self?.keyboardHandler.performUndo()
        }
    }

    private func setupHotkeyObserver() {
        // Re-sync hotkeys when settings change
        settings.$toggleHotkey
            .sink { [weak self] hotkey in self?.eventTapManager.toggleHotkey = hotkey }
            .store(in: &cancellables)
        settings.$undoEnabled
            .sink { [weak self] enabled in self?.eventTapManager.undoEnabled = enabled }
            .store(in: &cancellables)
        settings.$undoHotkey
            .sink { [weak self] hotkey in self?.eventTapManager.undoHotkey = hotkey }
            .store(in: &cancellables)
        settings.$inputMethod
            .sink { [weak self] method in self?.keyboardHandler.setInputMethod(method) }
            .store(in: &cancellables)
        settings.$spellCheckEnabled
            .sink { [weak self] enabled in self?.keyboardHandler.setEnglishDetection(enabled: enabled) }
            .store(in: &cancellables)

        // Keep recording state in sync with EventTapManager
        NotificationCenter.default.addObserver(forName: .hotkeyRecordingStateChanged, object: nil, queue: .main) { [weak self] note in
            let recording = (note.userInfo?["isRecording"] as? Bool) ?? false
            self?.eventTapManager.isHotkeyRecording = recording
        }
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        statusMenuViewModel = StatusBarViewModel()
        statusMenuViewModel.isVietnamese = keyboardHandler.isVietnamese

        statusMenuViewModel.onToggleVietnamese = { [weak self] in
            guard let self else { return }
            let newState = !self.keyboardHandler.isVietnamese
            self.keyboardHandler.setVietnameseMode(newState)
            self.statusMenuViewModel.isVietnamese = newState
            self.updateStatusBarIcon(isVietnamese: newState)
        }

        statusMenuViewModel.onOpenSettings = { [weak self] in
            self?.openSettings()
        }

        statusMenuViewModel.onQuit = {
            NSApplication.shared.terminate(nil)
        }

        // Popover
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: StatusMenuView(viewModel: statusMenuViewModel)
        )

        updateStatusBarIcon(isVietnamese: true)

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
        statusItem.button?.title = isVietnamese ? "V" : "E"
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
            self,
            selector: #selector(activeAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
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
        statusMenuViewModel.isVietnamese = savedState
        updateStatusBarIcon(isVietnamese: savedState)

        textInjector.needsAutocompleteFix = Self.browserBundleIDs.contains(bundleID)
        previousBundleID = bundleID
    }

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
