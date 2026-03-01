import Cocoa
import EverkeyEngine

class AppDelegate: NSObject, NSApplicationDelegate {
    private static let englishDetectionKey = "englishDetectionEnabled"

    private var statusItem: NSStatusItem!
    private let eventTapManager = EventTapManager()
    private let textInjector = CGTextInjector()
    private var keyboardHandler: KeyboardEventHandler!
    private var englishDetectionItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let detector = CompositeDetector([
            ConsonantClusterDetector(),
            InvalidCodaDetector(),
            InvalidVowelNucleiDetector(),
        ])
        keyboardHandler = KeyboardEventHandler(injector: textInjector, detector: detector)

        let isEnabled = UserDefaults.standard.object(forKey: Self.englishDetectionKey) as? Bool ?? true
        if !isEnabled {
            keyboardHandler.setEnglishDetection(enabled: false)
        }

        setupStatusBar()

        if !checkAccessibilityPermission() {
            promptAccessibilityPermission()
        }

        setupEventTap()
        setupAppSwitchObserver()
        setupSleepWakeObserver()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarTitle(isVietnamese: true)
        statusItem.menu = buildMenu()
    }

    private func updateStatusBarTitle(isVietnamese: Bool) {
        statusItem.button?.title = isVietnamese ? "V" : "E"
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        englishDetectionItem = NSMenuItem(
            title: "Phát hiện tiếng Anh",
            action: #selector(toggleEnglishDetection),
            keyEquivalent: ""
        )
        englishDetectionItem.target = self
        englishDetectionItem.state = keyboardHandler.isEnglishDetectionEnabled ? .on : .off
        menu.addItem(englishDetectionItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Everkey", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc private func toggleEnglishDetection() {
        let newValue = !keyboardHandler.isEnglishDetectionEnabled
        keyboardHandler.setEnglishDetection(enabled: newValue)
        englishDetectionItem.state = newValue ? .on : .off
        UserDefaults.standard.set(newValue, forKey: Self.englishDetectionKey)
    }

    // MARK: - Event Tap

    private func setupEventTap() {
        keyboardHandler.onToggle = { [weak self] isVietnamese in
            self?.updateStatusBarTitle(isVietnamese: isVietnamese)
        }

        eventTapManager.onEvent = { [weak self] proxy, type, event in
            guard let self = self else { return Unmanaged.passUnretained(event) }
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
        keyboardHandler.resetEngine()
    }

    // MARK: - Sleep/Wake

    private func setupSleepWakeObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleSleep() {
        eventTapManager.stop()
    }

    @objc private func handleWake() {
        if !eventTapManager.start() {
            NSLog("[Everkey] Failed to recreate event tap after wake.")
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
