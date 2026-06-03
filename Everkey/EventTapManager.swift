import CoreGraphics
import Foundation

let kEverkeyEventMarker: Int64 = 0x45564B59  // "EVKY"

class EventTapManager {
    fileprivate var eventTap: CFMachPort?
    fileprivate var runLoopSource: CFRunLoopSource?

    // Configurable hotkeys
    var toggleHotkey: Hotkey?
    var undoHotkey: Hotkey?          // nil = Escape (0x35) when undo is enabled
    var undoEnabled: Bool = false

    // Callbacks
    var onToggleHotkey: (() -> Void)?
    var onUndoTyping: (() -> Void)?
    var onEvent: ((CGEventTapProxy, CGEventType, CGEvent) -> Unmanaged<CGEvent>?)?

    // Suspend hotkey detection while user is recording a new hotkey
    var isHotkeyRecording: Bool = false

    // State for modifier-only hotkeys
    fileprivate var modifierOnlyState = ModifierOnlyState()

    func start() -> Bool {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: userInfo
        )

        if eventTap == nil {
            eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: eventTapCallback,
                userInfo: userInfo
            )
        }

        guard let tap = eventTap else { return false }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        runLoopSource = nil
        eventTap = nil
    }
}

// MARK: - Modifier-only hotkey state

struct ModifierOnlyState {
    var targetModifiersReached = false
    var hasTriggered = false
    var currentModifiers: ModifierFlags = []
}

// MARK: - C Callback

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = manager.eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }

    if event.getIntegerValueField(.eventSourceUserData) == kEverkeyEventMarker {
        return Unmanaged.passUnretained(event)
    }

    // ── Toggle hotkey ──────────────────────────────────────────────────────
    if !manager.isHotkeyRecording, let hotkey = manager.toggleHotkey {
        if hotkey.isModifierOnly {
            // Modifier-only: trigger on release after all required mods held
            if type == .flagsChanged {
                let eventMods = ModifierFlags(from: event.flags)
                let allMods: ModifierFlags = [.control, .shift, .option, .command, .function]
                let hasExactly = hotkey.modifiers.isSubset(of: eventMods)
                    && eventMods.intersection(allMods) == hotkey.modifiers

                if hasExactly {
                    if !manager.modifierOnlyState.targetModifiersReached {
                        manager.modifierOnlyState.targetModifiersReached = true
                        manager.modifierOnlyState.hasTriggered = false
                    }
                } else {
                    if manager.modifierOnlyState.targetModifiersReached
                        && !manager.modifierOnlyState.hasTriggered {
                        manager.modifierOnlyState.hasTriggered = true
                        DispatchQueue.main.async { manager.onToggleHotkey?() }
                    }
                    manager.modifierOnlyState.targetModifiersReached = false
                }
            } else if type == .keyDown && manager.modifierOnlyState.targetModifiersReached {
                // Key pressed while holding mods → cancel
                manager.modifierOnlyState.targetModifiersReached = false
                manager.modifierOnlyState.hasTriggered = true
            }
        } else if type == .keyDown {
            // Regular hotkey: match on keyDown
            let eventMods = ModifierFlags(from: event.flags)
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == hotkey.keyCode && eventMods == hotkey.modifiers {
                DispatchQueue.main.async { manager.onToggleHotkey?() }
                return nil  // consume
            }
        }
    }

    // ── Undo hotkey ────────────────────────────────────────────────────────
    if manager.undoEnabled && !manager.isHotkeyRecording && type == .keyDown {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let eventMods = ModifierFlags(from: event.flags)

        let triggered: Bool
        if let undo = manager.undoHotkey {
            triggered = keyCode == undo.keyCode && eventMods == undo.modifiers
        } else {
            // Default: Escape with no modifiers
            triggered = keyCode == 0x35 && eventMods.isEmpty
        }

        if triggered {
            DispatchQueue.main.async { manager.onUndoTyping?() }
            return nil  // consume
        }
    }

    // ── Delegate to app handler ────────────────────────────────────────────
    return manager.onEvent?(proxy, type, event) ?? Unmanaged.passUnretained(event)
}
